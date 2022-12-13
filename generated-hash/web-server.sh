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

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webServerServerName=
webPath=
webUser=
webGroup=
quiet=0

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

if [[ "${quiet}" == 0 ]]; then
  echo "Generating generated files hash in path: ${webPath}"
fi

filePatterns=( "di.xml" "extension_attributes.xml" "*.php" )
excludePaths=( "./dev/*" "./generated/*" "./pub/*" "./setup/*" "./status/*" "./update/*" )

hashCommand="find . -type f \("

first=1
for filePattern in "${filePatterns[@]}"; do
  if [[ "${first}" == 0 ]]; then
    hashCommand="${hashCommand}-o"
  fi
  hashCommand="${hashCommand} -iname '${filePattern}' "
  first=0
done

hashCommand="${hashCommand}\) ! -iname 'autoload.php' ! -iname 'autoload_*.php'"

for excludePath in "${excludePaths[@]}"; do
  hashCommand="${hashCommand} -not -path \"${excludePath}\""
done

hashCommand="${hashCommand} | sort -n | xargs -d '\n' md5sum | md5sum | awk '{print \$1}'"

cd "${webPath}"

oldIFS="${IFS}"
IFS=$'\n'
if [[ "${quiet}" == 1 ]]; then
  echo -n "${webServerServerName}:"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "$hashCommand"
  else
    bash -c "$hashCommand"
  fi
else
  hash=$(bash -c "$hashCommand")
  echo "Generated files hash: ${hash}"
fi
IFS="${oldIFS}"
