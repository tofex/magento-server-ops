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

if [[ -n "${memoryLimit}" ]]; then
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/composer-install/web-server.sh" \
    -m "${memoryLimit}"
else
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/composer-install/web-server.sh"
fi
