#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

cd "${currentPath}"

serverList=( $(ini-parse "${currentPath}/../env.properties" "no" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "no" "install" "magentoVersion")
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

echo "Extracting Magento hosts: "
"${currentPath}/get-magento-hosts-local.sh" \
  -v "${magentoVersion}" \
  -o "${databaseHost}" \
  -p "${databasePort}" \
  -r "${databaseUser}" \
  -s "${databasePassword}" \
  -n "${databaseName}"
