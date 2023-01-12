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

echo "Determining required locales"
backendLocaleList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-backend-locales.sh" -q) )
backendLocales=$(IFS=, ; echo "${backendLocaleList[*]}")

echo "Determining backend themes"
backendThemeList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-backend-themes.sh" -q) )
backendThemes=$(IFS=, ; echo "${backendThemeList[*]}")

echo "Determining required frontend locales"
frontendLocaleList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-frontend-locales.sh" -q) )
frontendLocales=$(IFS=, ; echo "${frontendLocaleList[*]}")

echo "Determining frontend themes"
frontendThemeList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-frontend-themes.sh" -q) )
frontendThemes=$(IFS=, ; echo "${frontendThemeList[*]}")

if [[ -n "${memoryLimit}" ]]; then
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-static/magento.sh" \
      -j "${backendLocales}" \
      -k "${backendThemes}" \
      -o "${frontendLocales}" \
      -s "${frontendThemes}" \
      -a "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
      -l "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
      -b "${phpExecutable}" \
      -i "${memoryLimit}" \
      -f
  else
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-static/magento.sh" \
      -j "${backendLocales}" \
      -k "${backendThemes}" \
      -o "${frontendLocales}" \
      -s "${frontendThemes}" \
      -a "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
      -l "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
      -b "${phpExecutable}" \
      -i "${memoryLimit}"
  fi
else
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-static/magento.sh" \
      -j "${backendLocales}" \
      -k "${backendThemes}" \
      -o "${frontendLocales}" \
      -s "${frontendThemes}" \
      -a "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
      -l "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
      -b "${phpExecutable}" \
      -f
  else
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-static/magento.sh" \
      -j "${backendLocales}" \
      -k "${backendThemes}" \
      -o "${frontendLocales}" \
      -s "${frontendThemes}" \
      -a "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
      -l "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
      -b "${phpExecutable}"
  fi
fi
