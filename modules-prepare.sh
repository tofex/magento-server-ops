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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

"${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/modules-prepare/magento.sh" \
  -s "script:${currentPath}/modules-diff/web-server.sh:modules-diff.sh" \
  -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
  -a "script:${currentPath}/static-clean/web-server.sh:static-clean.sh"
