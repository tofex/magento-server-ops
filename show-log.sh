#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Host name

Example: ${scriptName} -n dev_magento2_de
EOF
}

trim()
{
  echo -n "$1" | xargs
}

hostName=

while getopts hn:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) hostName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

"${currentPath}/../core/script/run.sh" "host:${hostName},webServer" "${currentPath}/show-log/host-web-server.sh"
