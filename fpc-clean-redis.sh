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
  redisFPC=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisFPC")
  if [[ -n "${redisFPC}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    port=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisFPC}" "port")
    database=$(ini-parse "${currentPath}/../env.properties" "yes" "${redisFPC}" "database")
    password=$(ini-parse "${currentPath}/../env.properties" "no" "${redisFPC}" "password")
    if [[ -z "${port}" ]]; then
      echo "No Redis port specified!"
      exit 1
    fi
    if [[ -z "${database}" ]]; then
      echo "No Redis database specified!"
      exit 1
    fi
    if [[ -z "${password}" ]]; then
      password="-"
    fi
    if [[ "${type}" == "local" ]]; then
      echo "--- Cleaning Redis FPC on local server: ${server} ---"
      "${currentPath}/redis-clean.sh" -o "localhost" -p "${port}" -d "${database}" -s "${password}"
    elif [[ "${type}" == "ssh" ]]; then
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ -z "${sshHost}" ]]; then
        echo "No SSH host specified!"
        exit 1
      fi
      echo "--- Cleaning Redis FPC on remote server: ${server} ---"
      "${currentPath}/redis-clean.sh" -o "${sshHost}" -p "${port}" -d "${database}" -s "${password}"
    fi
  fi
done
