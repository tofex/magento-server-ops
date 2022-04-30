#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Memory limit (optional)
  -f  Force (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

memoryLimit=
force=0

while getopts hm:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

cd "${currentPath}"

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")

  if [[ -n "${database}" ]]; then
    databasePort=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
    databaseUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
    databasePassword=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
    databaseName=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")

    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      databaseHost="localhost"
    else
      databaseHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    fi
  fi
done

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  exit 1
fi
if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi
if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi
if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi
if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

      echo "--- Generating static on local server: ${server} ---"
      if [[ -n "${memoryLimit}" ]]; then
        if [[ "${force}" == 1 ]]; then
          "${currentPath}/generate-static-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -o "${databaseHost}" \
            -p "${databasePort}" \
            -r "${databaseUser}" \
            -s "${databasePassword}" \
            -n "${databaseName}" \
            -m "${memoryLimit}" \
            -f
        else
          "${currentPath}/generate-static-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -o "${databaseHost}" \
            -p "${databasePort}" \
            -r "${databaseUser}" \
            -s "${databasePassword}" \
            -n "${databaseName}" \
            -m "${memoryLimit}"
        fi
      else
        if [[ "${force}" == 1 ]]; then
          "${currentPath}/generate-static-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -o "${databaseHost}" \
            -p "${databasePort}" \
            -r "${databaseUser}" \
            -s "${databasePassword}" \
            -n "${databaseName}" \
            -f
        else
          "${currentPath}/generate-static-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -o "${databaseHost}" \
            -p "${databasePort}" \
            -r "${databaseUser}" \
            -s "${databasePassword}" \
            -n "${databaseName}"
        fi
      fi
    fi
  fi
done
