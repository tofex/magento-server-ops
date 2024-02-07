#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help      Show this message
  --webPath   Web path of Magento installation
  --fileName  File to share

Example: ${scriptName} --webPath /var/www/magento/htdocs/ --fileName app/etc/config.php
EOF
}

webPath=
fileName=

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

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 0
fi

if [[ -z "${fileName}" ]]; then
  echo "No file specified"
  exit 1
fi

webPathFileName="${webPath}/${fileName}"
webPathFilePath=$(dirname "${webPathFileName}")

if [[ $(mount | grep " ${webPathFileName} " | wc -l) -gt 0 ]] || [[ $(mount | grep " ${webPathFilePath} " | wc -l) -gt 0 ]]; then
  echo "mounted"
elif [[ -L "${webPathFileName}" ]]; then
  echo "symlink"
elif [[ -e "${webPathFileName}" ]]; then
  echo "exists"
else
  echo "unavailable"
fi
