#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -q  Quiet mode, list only hash

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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ "${quiet}" == 1 ]]; then
  "${currentPath}/../core/script/web-server/all/quiet.sh" "${currentPath}/generated-hash/web-server.sh" -q
else
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/generated-hash/web-server.sh"
fi
