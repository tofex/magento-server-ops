#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --magentoVersion  Magento version
  --webPath         Web path of Magento installation
  --webUser         Web user (optional)
  --webGroup        Web group (optional)
  --phpExecutable   PHP executable (optional)
  --memoryLimit     Memory limit (optional)

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

magentoVersion=
webPath=
webUser=
webGroup=
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

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 0
fi

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup=$(id -g -n)
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ -n "${memoryLimit}" ]]; then
  echo "Using memory limit: ${memoryLimit}"
  if [[ "${magentoVersion:0:1}" == 1 ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit}  shell/indexer.php reindexall"
    else
      "${phpExecutable}" -dmemory_limit="${memoryLimit}" shell/indexer.php reindexall
    fi
  elif [[ "${magentoVersion:0:1}" == 2 ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit}  bin/magento indexer:reindex"
    else
      "${phpExecutable}" -dmemory_limit="${memoryLimit}" bin/magento indexer:reindex
    fi
  fi
else
  if [[ "${magentoVersion:0:1}" == 1 ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/indexer.php reindexall"
    else
      "${phpExecutable}" shell/indexer.php reindexall
    fi
  elif [[ "${magentoVersion:0:1}" == 2 ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento indexer:reindex"
    else
      "${phpExecutable}" bin/magento indexer:reindex
    fi
  fi
fi
