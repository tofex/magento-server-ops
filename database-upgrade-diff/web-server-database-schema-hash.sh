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
  --quiet                Quiet mode, list only changes

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webServerServerName=
webPath=
quiet=0

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
  echo "Invalid web path specified!"
  exit 1
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining current database schema hash of web server: ${webServerServerName} in path: ${webPath}"
fi

if [[ -f var/database_schema_hash.txt ]]; then
  hash=$(cat var/database_schema_hash.txt)
else
  hash=
fi

if [[ "${quiet}" == 1 ]]; then
  echo -n "${webServerServerName}:${hash}"
else
  echo "Schema files hash: ${hash}"
fi
