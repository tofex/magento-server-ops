#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help           Show this message
  --webPath        Web path of Magento installation
  --phpExecutable  PHP executable (optional)
  --quiet          Quiet mode, list only changes

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webPath=
phpExecutable=
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

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining inactive modules in path: ${webPath}"
fi

inactiveModuleNames=( $(bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {if (\\\$config['modules'][\\\$moduleName] == 0) {echo \\\"\\\$moduleName\n\\\";}}\" | sort -n") )

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#inactiveModuleNames[@]} inactive modules"
fi

if [[ "${#inactiveModuleNames[@]}" -gt 0 ]]; then
  if [[ "${quiet}" == 1 ]]; then
    echo "${inactiveModuleNames[@]}"
  else
    printf "%s\n" "${inactiveModuleNames[@]}"
  fi
fi
