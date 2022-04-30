#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -q  Quiet mode, list only changes

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

quiet=0

while getopts hq? option; do
  case "${option}" in
    h) usage; exit 1;;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

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

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      if [[ "${quiet}" == 0 ]]; then
        echo "--- Determining database upgrade diff on server: ${server} ---"
      fi
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      port=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
      user=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
      password=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
      name=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")

      if [[ "${quiet}" == 1 ]]; then
        "${currentPath}/database-upgrade-diff-local.sh" \
          -v "${magentoVersion}" \
          -w "${webPath}" \
          -o "localhost" \
          -p "${port}" \
          -r "${user}" \
          -s "${password}" \
          -n "${name}" \
          -q
      else
        "${currentPath}/database-upgrade-diff-local.sh" \
          -v "${magentoVersion}" \
          -w "${webPath}" \
          -o "localhost" \
          -p "${port}" \
          -r "${user}" \
          -s "${password}" \
          -n "${name}"
      fi
    fi
  fi
done
