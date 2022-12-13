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
  --webPath              Web path of Magento installation
  --webUser              Web user (optional)
  --webGroup             Web group (optional)
  --quiet                Quiet mode
  --save                 Save the hash

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webServerServerName=
webPath=
webUser=
webGroup=
quiet=0
save=0

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webServerServerName}" ]]; then
  echo "No server name specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 0
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

if [[ "${save}" == 1 ]]; then
  echo "Saving database schema files hash of web server: ${webServerServerName} in file: ${webPath}/var/database_schema_hash.txt"
elif [[ "${quiet}" == 0 ]]; then
  echo "Generating database schema files hash of web server: ${webServerServerName} in path: ${webPath}"
fi

hashCommand="find . -not -path \"./dev/*\" -not -path \"./vendor/magento/magento2-base/dev/*\" -name db_schema.xml | sort -n | xargs -d '\n' md5sum | md5sum | awk '{print \$1}'"

cd "${webPath}"

oldIFS="${IFS}"
IFS=$'\n'
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  hash=$(sudo -H -u "${webUser}" bash -c "$hashCommand")
else
  hash=$(bash -c "$hashCommand")
fi
IFS="${oldIFS}"

if [[ "${save}" == 1 ]]; then
  echo -n "${hash}" > "${webPath}/var/database_schema_hash.txt"
elif [[ "${quiet}" == 1 ]]; then
  echo -n "${webServerServerName}:${hash}"
else
  echo "Schema files hash: ${hash}"
fi
