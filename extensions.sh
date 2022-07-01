#!/bin/bash -e

scriptName="${0##*/}"
scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -b  PHP executable (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

phpExecutable=

while getopts hb:? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

if [[ ! -f ${currentPath}/../env.properties ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

if [[ ${magentoVersion:0:1} == "1" ]]; then
  requiredExtensions=( curl dom gd hash iconv mcrypt pdo_mysql simplexml soap )
elif [[ ${magentoVersion:0:3} == "2.3" ]]; then
  requiredExtensions=( bcmath ctype curl dom gd hash iconv intl mbstring openssl pdo_mysql simplexml soap spl xsl zip )
elif [[ ${magentoVersion:0:1} == "2" ]]; then
  requiredExtensions=( bcmath ctype curl dom gd hash iconv intl mbstring openssl pdo_mysql mcrypt simplexml soap spl xsl zip )
fi

rm -rf /tmp/required_extensions.list
touch /tmp/required_extensions.list
for requiredExtension in "${requiredExtensions[@]}"; do
  echo "${requiredExtension}" >> /tmp/required_extensions.list
done

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      echo "Checking on local server: ${server}"
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      cat <<EOF > "${webPath}/get_loaded_extensions.php"
<?php
\$extensions = get_loaded_extensions(false);
natcasesort(\$extensions);
echo implode(' ', \$extensions);
EOF
      IFS=" " baseUrls=( $("${phpExecutable}" "${currentPath}/../read_config_value.php" "${webPath}" web/*/base_url) )
      for baseUrl in "${baseUrls[@]}"; do
        baseUrl=$(echo "${baseUrl}" | sed 's:/*$::')
        echo "Checking url: ${baseUrl}"
        url="${baseUrl}/get_loaded_extensions.php"
        fileFound=$(curl -L -s --head "${url}" | grep -E "(HTTP/2|HTTP/1\.1) 200" | wc -l)
        if [[ "${fileFound}" -gt 0 ]]; then
          IFS=" " loadedExtensions=( $(curl -L -s "${url}") )
          rm -rf /tmp/loaded_extensions.list
          touch /tmp/loaded_extensions.list
          for loadedExtension in "${loadedExtensions[@]}"; do
            echo "${loadedExtension}" >> /tmp/loaded_extensions.list
          done
          IFS=$'\n' missingExtensions=( $(grep -Fxv -f /tmp/loaded_extensions.list /tmp/required_extensions.list | cat) )
          if [[ "${#missingExtensions[@]}" -eq 0 ]]; then
            echo "All extensions installed"
          else
            echo "Missing extensions:"
            for missingExtension in "${missingExtensions[@]}"; do
              echo "- ${missingExtension}"
            done
          fi
        else
          echo "Could not check: ${url}"
        fi
      done
      rm -rf "${webPath}/get_loaded_extensions.php"
    fi
  fi
done

echo "Checking cli"

cat <<EOF > /tmp/get_loaded_extensions.php
<?php
\$extensions = get_loaded_extensions(false);
natcasesort(\$extensions);
echo implode(' ', \$extensions);
EOF

IFS=" " loadedExtensions=( $("${phpExecutable}" /tmp/get_loaded_extensions.php) )
rm -rf /tmp/loaded_extensions.list
touch /tmp/loaded_extensions.list
for loadedExtension in "${loadedExtensions[@]}"; do
  echo "${loadedExtension}" >> /tmp/loaded_extensions.list
done
IFS=$'\n' missingExtensions=( $(grep -Fxv -f /tmp/loaded_extensions.list /tmp/required_extensions.list | cat) )
if [[ "${#missingExtensions[@]}" -eq 0 ]]; then
  echo "All extensions installed"
else
  echo "Missing extensions:"
  for missingExtension in "${missingExtensions[@]}"; do
    echo "- ${missingExtension}"
  done
fi

rm -rf /tmp/get_loaded_extensions.php
