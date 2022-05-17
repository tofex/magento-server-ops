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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  redisCache=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisCache")
  if [[ -n "${redisCache}" ]]; then
    database=$(ini-parse "${currentPath}/../env.properties" "no" "${redisCache}" "database")
    if [[ -n "${database}" ]]; then
      type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      port=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisCache}" "port")
      password=$(ini-parse "${currentPath}/../env.properties" "no" "${redisCache}" "password")
      if [[ -z "${port}" ]]; then
        echo "No Redis port specified!"
        exit 1
      fi
      if [[ -z "${password}" ]]; then
        password="-"
      fi
      if [[ "${type}" == "local" ]]; then
        echo "--- Cleaning Redis cache on local server: ${server} ---"
        "${currentPath}/redis-clean.sh" -o "localhost" -p "${port}" -d "${database}" -s "${password}"
      elif [[ "${type}" == "ssh" ]]; then
        sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
        if [[ -z "${sshHost}" ]]; then
          echo "No SSH host specified!"
          exit 1
        fi
        echo "--- Cleaning Redis cache on remote server: ${server} ---"
        "${currentPath}/redis-clean.sh" -o "${sshHost}" -p "${port}" -d "${database}" -s "${password}"
      fi
    else
      echo "No database configured for Redis cache"
    fi
  fi
done
