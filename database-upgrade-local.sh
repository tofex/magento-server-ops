#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -w  Web path of Magento installation
  -u  Web user (optional)
  -g  Web group (optional)
  -o  Database hostname, default: localhost
  -p  Port of the database, default: 3306
  -r  Database user
  -s  Database password
  -n  Database name
  -m  Memory limit (optional)
  -e  PHP executable (optional)
  -f  Force (optional)

Example: ${scriptName} -v 2.4.2 -w /var/www/magento/htdocs -r user -s password -n database
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
webPath=
webUser=
webGroup=
databaseHost="localhost"
databasePort="3306"
databaseUser=
databasePassword=
databaseName=
memoryLimit=
phpExecutable="php"
force=0

while getopts hv:w:u:g:o:p:r:n:s:n:e:m:e:f? option; do
  case ${option} in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    r) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    n) databaseName=$(trim "$OPTARG");;
    m) memoryLimit=$(trim "$OPTARG");;
    e) phpExecutable=$(trim "$OPTARG");;
    f) force=1;;
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

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  cd "${webPath}"
  if [[ -f shell/upgrade.php ]]; then
    echo "Running database upgrades in path: ${webPath}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/upgrade.php"
    else
      "${phpExecutable}" shell/upgrade.php
    fi
  fi
else
  echo "Determining database changes in path: ${webPath}"
  oldIFS="${IFS}"
  IFS=$'\n'
  changes=( $("${currentPath}/database-upgrade-diff-local.sh" \
    -w "${webPath}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -r "${databaseUser}" \
    -s "${databasePassword}" \
    -n "${databaseName}" \
    -v "${magentoVersion}" \
    -q) )
  IFS="${oldIFS}"

  if [[ "${force}" == 1 ]] || [[ "${#changes[@]}" -gt 0 ]]; then
    if [[ "${#changes[@]}" -gt 0 ]]; then
      ( IFS=$'\n'; echo "${changes[*]}" )
    fi
    if [[ "${force}" == 1 ]]; then
      echo "Forcing database upgrade"
    fi

    "${currentPath}/../ops/generated-clean-local.sh" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"

    echo "Running database upgrades in path: ${webPath}"
    cd "${webPath}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} bin/magento setup:upgrade --keep-generated"
      else
        sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento setup:upgrade --keep-generated"
      fi
    else
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        ${phpExecutable} -dmemory_limit="${memoryLimit}" bin/magento setup:upgrade --keep-generated
      else
        ${phpExecutable} bin/magento setup:upgrade --keep-generated
      fi
    fi
  else
    echo "No database upgrade required"
  fi
fi
