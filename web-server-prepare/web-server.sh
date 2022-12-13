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

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

magentoVersion=
webServerType=
webPath=
webUser=
webGroup=

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

if [[ -z "${webServerType}" ]]; then
  echo "No web server type specified!"
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

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

if [[ -d generated ]]; then
  sudo find generated/ -maxdepth 1 -type d -exec chmod 0775 {} \;
fi
if [[ -d pub ]]; then
  sudo find pub/ -maxdepth 1 -type d -exec chmod 0775 {} \;
fi
if [[ -d var ]]; then
  sudo find var/ -maxdepth 1 -type d -exec chmod 0775 {} \;
fi
if [[ -d var/log ]]; then
  sudo find var/log -exec chmod 0775 {} \;
fi
if [[ -d vendor ]]; then
  sudo find vendor/ -maxdepth 1 -type d -exec chmod 0775 {} \;
fi

if [[ "${webServerType}" == "apache" ]] || [[ "${webServerType}" == "apache_php" ]]; then
  sudo service apache2 reload
fi
