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
  -i  Memory limit (optional)
  -f  Force (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

phpExecutable=
memoryLimit=
force=0

while getopts hb:i:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) phpExecutable=$(trim "$OPTARG");;
    i) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

magentoVersion=$("${currentPath}/../core/server/magento/version.sh")

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh" \
      -b "${phpExecutable}" \
      -i "${memoryLimit}"
  else
    "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh" \
      -b "${phpExecutable}"
  fi
else
  if [[ "${force}" == 1 ]]; then
    if [[ -n "${memoryLimit}" ]]; then
      "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
        -l "script:${currentPath}/generated-clean/web-server.sh" \
        -b "${phpExecutable}" \
        -i "${memoryLimit}"
    else
      "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
        -l "script:${currentPath}/generated-clean/web-server.sh" \
        -b "${phpExecutable}"
    fi
  else
    echo "Determining database changes"

    oldIFS="${IFS}"
    IFS=$'\n'
    changes=( $("${currentPath}/database-upgrade-diff.sh" -q) )
    IFS="${oldIFS}"

    if [[ "${#changes[@]}" -gt 0 ]]; then
      ( IFS=$'\n'; echo "${changes[*]}" )

      if [[ -n "${memoryLimit}" ]]; then
        "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
          -l "script:${currentPath}/generated-clean/web-server.sh" \
          -b "${phpExecutable}" \
          -i "${memoryLimit}"
      else
        "${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/database-upgrade/magento.sh" \
          -l "script:${currentPath}/generated-clean/web-server.sh" \
          -b "${phpExecutable}"
      fi
    else
      echo "No changes found"
    fi
  fi
fi
