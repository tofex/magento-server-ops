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
  -q  Quiet mode, list only

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

if [[ "${quiet}" == 1 ]]; then
  "${currentPath}/../core/script/magento/database/quiet.sh" "${currentPath}/get-magento-hosts/magento-database.sh"
else
  echo "Extracting Magento hosts: "
  "${currentPath}/../core/script/magento/database.sh" "${currentPath}/get-magento-hosts/magento-database.sh"
fi
