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
  -n  List only unknown modules
  -m  List only missing modules
  -q  Quiet mode, list only changes
  -e  PHP executable (optional)

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
listOnlyUnknown=0
listOnlyMissing=0
quiet=0
phpExecutable="php"

while getopts hw:u:g:nmqe:? option; do
  case "${option}" in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    n) listOnlyUnknown=1;;
    m) listOnlyMissing=1;;
    q) quiet=1;;
    e) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining configured modules"
fi
rm -rf /tmp/modules-configured.list
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {echo \\\"\\\$moduleName\n\\\";}\" | sort -n > /tmp/modules-configured.list"
else
  bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {echo \\\"\\\$moduleName\n\\\";}\" | sort -n > /tmp/modules-configured.list"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining code modules"
fi
rm -rf /tmp/modules-code.list
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "find . -name module.xml -not -path \"./dev/*\" -not -path \"./generated/*\" -not -path \"./pub/*\" -not -path \"./setup/*\" -not -path \"./status/*\" -not -path \"./update/*\" -not -path \"./vendor/magento/magento2-base/dev/*\" -not -path \"./vendor/amzn/amazon-payments-magento-2-plugin/src/*\" -not -path \"./vendor/mirasvit/module-report-api/src/*\" -exec grep -m 1 \"<module\" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*/\1/' | uniq | sort -n > /tmp/modules-code.list"
else
  bash -c "find . -name module.xml -not -path \"./dev/*\" -not -path \"./generated/*\" -not -path \"./pub/*\" -not -path \"./setup/*\" -not -path \"./status/*\" -not -path \"./update/*\" -not -path \"./vendor/magento/magento2-base/dev/*\" -not -path \"./vendor/amzn/amazon-payments-magento-2-plugin/src/*\" -not -path \"./vendor/mirasvit/module-report-api/src/*\" -exec grep -m 1 \"<module\" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*/\1/' | uniq | sort -n > /tmp/modules-code.list"
fi

if [[ "${listOnlyMissing}" == 0 ]]; then
  unknownModules=( $( grep -Fxv -f /tmp/modules-configured.list /tmp/modules-code.list | cat ) )
  if [[ "${#unknownModules[@]}" -gt 0 ]]; then
    if [[ "${quiet}" == 0 ]]; then
      echo "Found ${#unknownModules[@]} unknown module(s):"
    fi
    ( IFS=$'\n'; echo "${unknownModules[*]}" )
  elif [[ "${quiet}" == 0 ]]; then
    echo "Found no unknown modules"
  fi
fi

if [[ "${listOnlyUnknown}" == 0 ]]; then
  missingModules=( $( grep -Fxv -f /tmp/modules-code.list /tmp/modules-configured.list | cat ) )
  if [[ "${#missingModules[@]}" -gt 0 ]]; then
    if [[ "${quiet}" == 0 ]]; then
      echo "Found ${#missingModules[@]} missing module(s):"
    fi
    ( IFS=$'\n'; echo "${missingModules[*]}" )
  elif [[ "${quiet}" == 0 ]]; then
    echo "Found no missing modules"
  fi
fi
