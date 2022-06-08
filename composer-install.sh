#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Memory limit (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

memoryLimit=

while getopts hm:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) memoryLimit=$(trim "$OPTARG");;
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

if [[ -n "${memoryLimit}" ]]; then
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/composer-install/web-server.sh" \
    -m "${memoryLimit}"
else
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/composer-install/web-server.sh"
fi
