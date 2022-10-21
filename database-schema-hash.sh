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
  -q  Quiet mode, list only hash
  -s  Save the hash

Example: ${scriptName} -s
EOF
}

trim()
{
  echo -n "$1" | xargs
}

quiet=0
save=0

while getopts hqs? option; do
  case "${option}" in
    h) usage; exit 1;;
    q) quiet=1;;
    s) save=1;;
    ?) usage; exit 1;;
  esac
done

if [[ "${quiet}" == 1 ]]; then
  if [[ "${save}" == 1 ]]; then
    "${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-schema-hash/web-server.sh" --quiet --save
  else
    "${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-schema-hash/web-server.sh" --quiet
  fi
else
  if [[ "${save}" == 1 ]]; then
    "${currentPath}/../core/script/run.sh" "webServer:single" "${currentPath}/database-schema-hash/web-server.sh" --save
  else
    "${currentPath}/../core/script/run.sh" "webServer:single" "${currentPath}/database-schema-hash/web-server.sh"
  fi
fi
