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

while getopts hv:w:u:g:o:p:r:n:s:n:m:e:f? option; do
  case "${option}" in
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
  echo "No web path available!"
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

cd "${webPath}"

echo "Generating static content in path: ${webPath}"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  if [[ -f "shell/porto/theme/generate_css.php" ]]; then
    echo "Generating Porto theme"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/porto/theme/generate_css.php"
    else
      "${phpExecutable}" shell/porto/theme/generate_css.php
    fi
  fi
  if [[ -f "shell/ultimo/theme/generate_css.php" ]]; then
    echo "Generating Ultimo theme"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/ultimo/theme/generate_css.php"
    else
      "${phpExecutable}" shell/ultimo/theme/generate_css.php
    fi
  fi
  if [[ -f "shell/deployed_version.php" ]]; then
    echo "Generating deployed version number"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} shell/deployed_version.php"
    else
      "${phpExecutable}" shell/deployed_version.php
    fi
  fi
else
  echo "Determining static files hash in path: ${webPath}"
  staticHash=$("${currentPath}/static-hash-local.sh" -w "${webPath}" -u "${webUser}" -g "${webGroup}" -q)

  generateRequired=0
  if [[ ! -f pub/static/deployed_version.txt ]]; then
    echo "Generating required because no pub/static/deployed_version.txt was found"
    generateRequired=1
  else
    if [[ ! -f pub/static/files_hash.txt ]]; then
      echo "Generating required because no previous static files hash was found"
      generateRequired=1
    else
      echo "Reading previous static files hash"
      previousStaticHash=$(cat pub/static/files_hash.txt)
      if [[ "${staticHash}" != "${previousStaticHash}" ]]; then
        echo "Generating required because previous static hash is different"
        generateRequired=1
      else
        if [[ "${force}" == 1 ]]; then
          echo "Generating required because of force mode while previous static hash matches"
          generateRequired=1
        else
          echo "No generating required because previous static hash matches"
        fi
      fi
    fi
  fi

  if [[ "${generateRequired}" == 1 ]]; then
    "${currentPath}/static-clean-local.sh" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"

    export MYSQL_PWD="${databasePassword}"

    echo "Determining required locales"
    backendLocales=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(interface_locale) FROM admin_user;") )
    echo "Determining backend themes"
    backendThemes=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(theme_path) FROM theme WHERE area = \"adminhtml\" AND theme_id NOT IN (SELECT DISTINCT(parent_id) FROM theme WHERE area = \"adminhtml\" AND parent_id IS NOT NULL);") )
    echo "Determining required frontend locales"
    frontendLocales=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(value) FROM core_config_data WHERE path = \"general/locale/code\";") )
    echo "Determining frontend theme ids"
    frontendThemeIds=$(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT GROUP_CONCAT(value) FROM core_config_data WHERE path = \"design/theme/theme_id\";")
    if [[ -n "${frontendThemeIds}" ]] && [[ "${frontendThemeIds}" != "NULL" ]]; then
      echo "Determining frontend theme paths"
      frontendThemes=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT theme_path FROM theme WHERE theme_id IN (${frontendThemeIds});") )
    else
      frontendThemes=( "Magento/luma" )
    fi

    backendCommand="bin/magento setup:static-content:deploy"
    for backendLocale in "${backendLocales[@]}"; do
      backendCommand="${backendCommand} ${backendLocale}"
    done
    for backendTheme in "${backendThemes[@]}"; do
      backendCommand="${backendCommand} --theme ${backendTheme}"
    done
    backendCommand="${backendCommand} --area adminhtml --force"

    frontendCommand="bin/magento setup:static-content:deploy"
    for frontendLocale in "${frontendLocales[@]}"; do
      frontendCommand="${frontendCommand} ${frontendLocale}"
    done
    for frontendTheme in "${frontendThemes[@]}"; do
      frontendCommand="${frontendCommand} --theme ${frontendTheme}"
    done
    frontendCommand="${frontendCommand} --area frontend --force"

    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      echo "Generating backend theme(s): ${backendThemes[*]} for locale(s): ${backendLocales[*]} with user: ${webUser}"
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${backendCommand}"
      else
        sudo -H -u "${webUser}" bash -c "${phpExecutable} ${backendCommand}"
      fi
      echo "Generating frontend theme(s): ${frontendThemes[*]} for locale(s): ${frontendLocales[*]} with user: ${webUser}"
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${frontendCommand}"
      else
        sudo -H -u "${webUser}" bash -c "${phpExecutable} ${frontendCommand}"
      fi
    else
      echo "Generating backend theme(s): ${backendThemes[*]} for locale(s): ${backendLocales[*]}"
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${backendCommand}"
      else
        bash -c "${phpExecutable} ${backendCommand}"
      fi
      echo "Generating frontend theme(s): ${frontendThemes[*]} for locale(s): ${frontendLocales[*]}"
      if [[ -n "${memoryLimit}" ]]; then
        echo "Using memory limit: ${memoryLimit}"
        bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${frontendCommand}"
      else
        bash -c "${phpExecutable} ${frontendCommand}"
      fi
    fi
  fi

  echo "${staticHash}" > pub/static/files_hash.txt

  if [[ -d "vendor/tofex/m2-porto" ]]; then
    echo "Generating Porto theme"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento porto:theme:generate-css"
    else
      "${phpExecutable}" bin/magento porto:theme:generate-css
    fi
  fi
  if [[ -d "vendor/tofex/m2-ultimo" ]]; then
    echo "Generating Ultimo theme"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento ultimo:theme:generate-css"
    else
      "${phpExecutable}" bin/magento ultimo:theme:generate-css
    fi
  fi
fi
