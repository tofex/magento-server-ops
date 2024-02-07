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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

environment=$(ini-parse "${currentPath}/../env.properties" "no" "system" "environment")

echo "Determining required backend locales"
backendLocaleList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-backend-locales.sh" -q) )
if [[ "${#backendLocaleList[@]}" -gt 0 ]]; then
  backendLocales=$(IFS=, ; echo "${backendLocaleList[*]}")
else
  backendLocales="-"
fi

echo "Determining backend themes"
backendThemeList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-backend-themes.sh" -q) )
backendThemes=$(IFS=, ; echo "${backendThemeList[*]}")

echo "Determining required frontend locales"
databaseFrontendLocaleList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-frontend-locales.sh" -q) )
if [[ -n "${environment}" ]]; then
  webServerFrontendLocaleList=( $("${currentPath}/../core/script/magento/web-server/quiet.sh" "${currentPath}/generate-static/web-server-frontend-locales.sh" -e "${environment}" -q) )
else
  webServerFrontendLocaleList=( $("${currentPath}/../core/script/magento/web-server/quiet.sh" "${currentPath}/generate-static/web-server-frontend-locales.sh" -q) )
fi
if [[ "${#webServerFrontendLocaleList[@]}" -gt 0 ]]; then
  oldIFS="${IFS}"
  IFS=$'\n'
  frontendLocaleList=($(for locale in "${databaseFrontendLocaleList[@]}" "${webServerFrontendLocaleList[@]}"; do echo "${locale}"; done | sort -du))
  IFS="${oldIFS}"
  frontendLocales=$(IFS=, ; echo "${frontendLocaleList[*]}")
else
  frontendLocales="-"
fi

echo "Determining frontend themes"
frontendThemeList=( $("${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/generate-static/database-frontend-themes.sh" -q) )
frontendThemes=$(IFS=, ; echo "${frontendThemeList[*]}")

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --memoryLimit "${memoryLimit}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --memoryLimit "${memoryLimit}"
    fi
  else
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --phpExecutable "${phpExecutable}"
    fi
  fi
else
  if [[ -n "${memoryLimit}" ]]; then
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --memoryLimit "${memoryLimit}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --memoryLimit "${memoryLimit}"
    fi
  else
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:all" "${currentPath}/generate-static/magento.sh" \
        --backendLocales "${backendLocales}" \
        --backendThemes "${backendThemes}" \
        --frontendLocales "${frontendLocales}" \
        --frontendThemes "${frontendThemes}" \
        --staticHashScript "script:${currentPath}/static-hash/web-server.sh:static-hash.sh" \
        --staticCleanScript "script:${currentPath}/static-clean/web-server.sh:static-clean.sh"
    fi
  fi
fi
