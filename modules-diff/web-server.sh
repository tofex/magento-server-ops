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
  -b  PHP executable (optional)
  -k  List only unknown modules
  -m  List only missing modules
  -q  Quiet mode, list only changes

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
phpExecutable=
listOnlyUnknown=0
listOnlyMissing=0
quiet=0

while getopts hn:w:u:g:t:v:p:z:x:y:b:kmq? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    b) phpExecutable=$(trim "$OPTARG");;
    k) listOnlyUnknown=1;;
    m) listOnlyMissing=1;;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

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

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining configured modules"
fi
rm -rf /tmp/modules-configured.list
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {echo \\\"\\\$moduleName\n\\\";}\" | sort -n | grep -v \"^Magento_ComposerRootUpdatePlugin\" > /tmp/modules-configured.list"
else
  bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {echo \\\"\\\$moduleName\n\\\";}\" | sort -n | grep -v \"^Magento_ComposerRootUpdatePlugin\" > /tmp/modules-configured.list"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining code modules"
fi
rm -rf /tmp/modules-code.list
if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  sudo -H -u "${webUser}" bash -c "find . -name module.xml -not -path \"./dev/*\" -not -path \"./generated/*\" -not -path \"./pub/*\" -not -path \"./setup/*\" -not -path \"./status/*\" -not -path \"./update/*\" -not -path \"./vendor/magento/magento2-base/dev/*\" -not -path \"./vendor/magento/composer-root-update-plugin/*\" -not -path \"./vendor/amzn/amazon-payments-magento-2-plugin/src/*\" -not -path \"./vendor/mirasvit/module-report-api/src/*\" -exec grep -m 1 \"<module\" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*/\1/' | uniq | sort -n | grep -v \"^Magento_ComposerRootUpdatePlugin\" > /tmp/modules-code.list"
else
  bash -c "find . -name module.xml -not -path \"./dev/*\" -not -path \"./generated/*\" -not -path \"./pub/*\" -not -path \"./setup/*\" -not -path \"./status/*\" -not -path \"./update/*\" -not -path \"./vendor/magento/magento2-base/dev/*\" -not -path \"./vendor/magento/composer-root-update-plugin/*\" -not -path \"./vendor/amzn/amazon-payments-magento-2-plugin/src/*\" -not -path \"./vendor/mirasvit/module-report-api/src/*\" -exec grep -m 1 \"<module\" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*/\1/' | uniq | sort -n | grep -v \"^Magento_ComposerRootUpdatePlugin\" > /tmp/modules-code.list"
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
