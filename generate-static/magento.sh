#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                 Show this message
  --magentoVersion       Magento version
  --webServerServerName  Name of web server
  --webPath              Path of deployment
  --webUser              Web user (optional)
  --webGroup             Web group (optional)
  --backendLocales       List of backend locales to generate
  --backendThemes        List of backend themes to generate
  --frontendLocales      List of frontend locales to generate
  --frontendThemes       List of frontend themes to generate
  --staticHashScript     Script to generate the static hash
  --staticCleanScript    Script to clean the static hash
  --phpExecutable        PHP executable (optional)
  --memoryLimit          Memory limit (optional)
  --force                Force generating (optional)

Example: ${scriptName} --magentoVersion 2.3.7 --webServerServerName webserver --webPath /var/www/magento/htdocs
EOF
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
webServerServerName=
webPath=
webUser=
webGroup=
backendLocales=
backendThemes=
frontendLocales=
frontendThemes=
staticHashScript=
staticCleanScript=
phpExecutable=
memoryLimit=
force=0

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

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

if [[ -z "${webServerServerName}" ]]; then
  echo "No server name specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
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

if [[ -z "${staticHashScript}" ]]; then
  echo "No generated hash script specified!"
  usage
  exit 1
fi

if [[ -z "${staticCleanScript}" ]]; then
  echo "No generated clean script specified!"
  usage
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
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
  staticHash=$("${staticHashScript}" \
    -n "${webServerServerName}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -q)

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
    "${staticCleanScript}" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"

    if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 1 ]]; then
      readarray -d , -t backendLocaleList < <(printf '%s' "${backendLocales}")
      readarray -d , -t frontendLocaleList < <(printf '%s' "${frontendLocales}")
      localeList=( "${backendLocaleList[@]}" "${frontendLocaleList[@]}" )
      localeList=( $(echo "${localeList[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ') )

      command="bin/magento setup:static-content:deploy"
      for locale in "${localeList[@]}"; do
        command="${command} ${locale}"
      done

      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        echo "Generating locale(s): ${localeList[*]} with user: ${webUser}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${command}"
        else
          sudo -H -u "${webUser}" bash -c "${phpExecutable} ${command}"
        fi
      else
        echo "Generating locale(s): ${localeList[*]}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${command}"
        else
          bash -c "${phpExecutable} ${command}"
        fi
      fi
    else
      readarray -d , -t backendLocaleList < <(printf '%s' "${backendLocales}")
      readarray -d , -t backendThemeList < <(printf '%s' "${backendThemes}")
      readarray -d , -t frontendLocaleList < <(printf '%s' "${frontendLocales}")
      readarray -d , -t frontendThemeList < <(printf '%s' "${frontendThemes}")

      backendCommand="bin/magento setup:static-content:deploy"
      for backendLocale in "${backendLocaleList[@]}"; do
        backendCommand="${backendCommand} ${backendLocale}"
      done
      for backendTheme in "${backendThemeList[@]}"; do
        backendCommand="${backendCommand} --theme ${backendTheme}"
      done
      backendCommand="${backendCommand} --area adminhtml --force"

      frontendCommand="bin/magento setup:static-content:deploy"
      for frontendLocale in "${frontendLocaleList[@]}"; do
        frontendCommand="${frontendCommand} ${frontendLocale}"
      done
      for frontendTheme in "${frontendThemeList[@]}"; do
        frontendCommand="${frontendCommand} --theme ${frontendTheme}"
      done
      frontendCommand="${frontendCommand} --area frontend --force"

      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        echo "Generating backend theme(s): ${backendThemeList[*]} for locale(s): ${backendLocaleList[*]} with user: ${webUser}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${backendCommand}"
        else
          sudo -H -u "${webUser}" bash -c "${phpExecutable} ${backendCommand}"
        fi
        echo "Generating frontend theme(s): ${frontendThemeList[*]} for locale(s): ${frontendLocaleList[*]} with user: ${webUser}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${frontendCommand}"
        else
          sudo -H -u "${webUser}" bash -c "${phpExecutable} ${frontendCommand}"
        fi
      else
        echo "Generating backend theme(s): ${backendThemeList[*]} for locale(s): ${backendLocaleList[*]}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${backendCommand}"
        else
          bash -c "${phpExecutable} ${backendCommand}"
        fi
        echo "Generating frontend theme(s): ${frontendThemeList[*]} for locale(s): ${frontendLocaleList[*]}"
        if [[ -n "${memoryLimit}" ]]; then
          echo "Using memory limit: ${memoryLimit}"
          bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} ${frontendCommand}"
        else
          bash -c "${phpExecutable} ${frontendCommand}"
        fi
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
