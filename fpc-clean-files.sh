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
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")
      echo "--- Cleaning file FPC on local server: ${server} ---"
      "${currentPath}/fpc-clean-files-local.sh" -w "${webPath}" -u "${webUser}" -g "${webGroup}"
    elif [[ "${type}" == "ssh" ]]; then
      sshUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "user")
      sshHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ -z "${sshUser}" ]]; then
        echo "No SSH user specified!"
        exit 1
      fi
      if [[ -z "${sshHost}" ]]; then
        echo "No SSH host specified!"
        exit 1
      fi
      echo "--- Cleaning file FPC on remote server: ${server} ---"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/fpc-clean-local.sh"
      scp -q "${currentPath}/fpc-clean-files-local.sh" "${sshUser}@${sshHost}:/tmp/fpc-clean-files-local.sh"
      ssh "${sshUser}@${sshHost}" /tmp/fpc-clean-files-local.sh -w "${webPath}"
    fi
  fi
done
