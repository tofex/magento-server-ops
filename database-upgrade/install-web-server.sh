#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Web path
  -u  Web user (optional)
  -g  Web group (optional)
  -l  Generated code clean script
  -b  PHP executable (optional)
  -i  Memory limit (optional)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs
EOF
}

magentoVersion=
webPath=
webUser=
webGroup=
generatedCleanScript=
phpExecutable=
memoryLimit=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup=$(id -g -n)
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${generatedCleanScript}" ]]; then
  echo "No generated clean script specified!"
  usage
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  if [[ -f shell/upgrade.php ]]; then
    echo "Running database upgrades in path: ${webPath}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/upgrade.php"
    else
      "${phpExecutable}" shell/upgrade.php
    fi
  fi
else
  "${generatedCleanScript}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}"

  echo "Running database upgrades in path: ${webPath}"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    if [[ -n "${memoryLimit}" ]]; then
      echo "Using memory limit: ${memoryLimit}"
      sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} bin/magento setup:upgrade --keep-generated"
    else
      sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento setup:upgrade --keep-generated"
    fi
  else
    if [[ -n "${memoryLimit}" ]]; then
      echo "Using memory limit: ${memoryLimit}"
      "${phpExecutable}" -dmemory_limit="${memoryLimit}" bin/magento setup:upgrade --keep-generated
    else
      "${phpExecutable}" bin/magento setup:upgrade --keep-generated
    fi
  fi
fi
