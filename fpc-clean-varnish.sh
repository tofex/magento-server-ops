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

hostList=( $(ini-parse "${currentPath}/../env.properties" "no" "system" "host") )
if [[ "${#hostList[@]}" -eq 0 ]]; then
  echo "No hosts specified!"
  exit 1
fi

varnishHosts="-"
for host in "${hostList[@]}"; do
  hostName=$(echo "${host}" | cut -d: -f1)
  if [[ "${varnishHosts}" == "-" ]]; then
    varnishHosts="${hostName}"
  else
    varnishHosts="${varnishHosts},${hostName}"
  fi
done

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  varnish=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "varnish")
  if [[ -n "${varnish}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    adminPort=$(ini-parse "${currentPath}/../env.properties" "no" "${varnish}" "adminPort")
    secretFile="/etc/varnish/secret"
    if [[ "${type}" == "local" ]]; then
      echo "--- Cleaning Varnish FPC on local server: ${server} ---"
      "${currentPath}/fpc-clean-varnish-local.sh" -v "localhost" -a "${adminPort}" -f "${secretFile}" -o "${varnishHosts}"
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
      echo "--- Cleaning Varnish FPC on remote server: ${server} ---"
      echo "Copying script to ${sshUser}@${sshHost}:/tmp/fpc-clean-varnish-local.sh"
      scp -q "${currentPath}/fpc-clean-varnish-local.sh" "${sshUser}@${sshHost}:/tmp/fpc-clean-varnish-local.sh"
      ssh "${sshUser}@${sshHost}" /tmp/fpc-clean-varnish-local.sh -v "${sshHost}" -a "${adminPort}" -f "${secretFile}" -o "${varnishHosts}"
    fi
  fi
done
