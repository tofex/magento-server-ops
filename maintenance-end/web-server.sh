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
  --webUser   Web user (optional)
  --webGroup  Web group (optional)

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webPath=
webUser=
webGroup=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

echo "Disabling maintenance mode in path: ${webPath}"
if [[ -f bin/magento ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "rm -rf var/.maintenance.flag"
  else
    rm -rf var/.maintenance.flag
  fi
else
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "rm -rf maintenance.flag"
  else
    rm -rf maintenance.flag
  fi
fi
