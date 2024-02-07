#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                 Show this message
  --webServerServerName  Server name
  --envPropertyFile      Environment property file
  --webPath              Web path of Magento installation
  --sharedPath           Shared path, default: shared
  --fileName             File to move
  --revert               Revert moving file to shared

Example: ${scriptName} --webServerServerName ws --envPropertyFile /path/to/env.properties --webPath /var/www/magento/htdocs/ --fileName app/etc/config.php
EOF
}

webServerServerName=
envPropertyFile=
webPath=
sharedPath=
fileName=
revert=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webServerServerName}" ]]; then
  echo "No web server server name specified!"
  usage
  exit 1
fi

if [[ -z "${envPropertyFile}" ]]; then
  echo "No environment property file specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="shared"
fi

if [[ -z "${fileName}" ]]; then
  echo "No file name specified!"
  usage
  exit 1
fi

if [[ -z "${revert}" ]]; then
  revert=0
fi

webRoot=$(dirname "${webPath}")

if [[ "${revert}" == 0 ]]; then
  addLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
  echo "Adding link: ${addLink} to deployment"
  ini-set "${envPropertyFile}" "no" "${webServerServerName}" "link" "${addLink}"
else
  removeLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
  echo "Removing link: ${removeLink} from deployment"
  ini-del "${envPropertyFile}" "${webServerServerName}" "link" "${removeLink}"
fi
