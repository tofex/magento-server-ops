#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path of Magento installation
  -u  Web user (optional)
  -g  Web group (optional)

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=

while getopts hw:u:g:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 1
fi

cd "${webPath}"

if [[ -f "${webPath}/app/etc/local.xml" ]]; then
  magentoVersion=1
else
  magentoVersion=2
fi

if [[ "${magentoVersion}" == 1 ]]; then
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    magentoSpecificVersion=$(sudo -H -u "${webUser}" bash -c "php -r \"require 'app/Mage.php'; echo Mage::getVersion();\"")
  else
    magentoSpecificVersion=$(php -r "require 'app/Mage.php'; echo Mage::getVersion();")
  fi
  if [[ "${magentoSpecificVersion}" == "1.9.4.5" ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      openMageVersion=$(sudo -H -u "${webUser}" bash -c "php -r \"require 'app/Mage.php'; if (method_exists(Mage::class, 'getOpenMageVersion')) {echo Mage::getOpenMageVersion();}\"")
    else
      openMageVersion=$(php -r "require 'app/Mage.php'; if (method_exists(Mage::class, 'getOpenMageVersion')) {echo Mage::getOpenMageVersion();}")
    fi
    if [[ -n "${openMageVersion}" ]]; then
      magentoSpecificVersion="${openMageVersion}"
    fi
  fi
else
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    magentoSpecificVersion=$(sudo -H -u "${webUser}" bash -c "bin/magento --version | cut -d' ' -f4 | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'")
  else
    magentoSpecificVersion=$(bin/magento --version | cut -d' ' -f4 | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g')
  fi
  if [[ -z "${magentoSpecificVersion}" ]]; then
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      magentoSpecificVersion=$(sudo -H -u "${webUser}" bash -c "bin/magento --version | cut -d' ' -f3")
    else
      magentoSpecificVersion=$(bin/magento --version | cut -d' ' -f3)
    fi
  fi
fi

echo "${magentoSpecificVersion}"
