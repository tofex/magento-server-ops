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

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

if [[ -d var/session/ ]]; then
  sessionFiles=$(ls -A var/session/ | wc -l)
  if [[ "${sessionFiles}" -gt 0 ]]; then
    echo "Removing Magento session files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -n -H -u "${webUser}" bash -c "find var/session/ -type f -exec rm {} \;"
    else
      find var/session/ -type f -exec rm {} \;
    fi
  fi
fi

if [[ -d /var/lib/php/sessions/ ]]; then
  sessionFiles=$(sudo -n ls -A /var/lib/php/sessions/ 2>/dev/null | wc -l)
  if [[ "${sessionFiles}" -gt 0 ]]; then
    echo "Removing PHP session files"
    sudo -n find /var/lib/php/sessions/ -type f -exec rm {} \;
  fi
fi
