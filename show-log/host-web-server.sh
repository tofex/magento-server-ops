#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help      Show this message
  --webPath   Web path
  --hostName  Host name

Example: ${scriptName} --webPath /var/www/magento/htdocs --hostName dev_magento2_de
EOF
}

webPath=
hostName=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${hostName}" ]]; then
  echo "No host name specified!"
  usage
  exit 1
fi

webRoot=$(dirname "${webPath}")

logFile="${webRoot}/log/${hostName}-apache-ssl-error.log"

if [[ -f "${logFile}" ]]; then
  less "${logFile}"
else
  >&2 echo "Log file not found at: ${logFile}"
  exit 1
fi
