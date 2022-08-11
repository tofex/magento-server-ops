#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Path of deployment
  -u  Web user (optional)
  -g  Web group (optional)
  -a  Generated hash script
  -l  Generated code clean script
  -b  PHP executable (optional)
  -i  Memory limit (optional)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
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
serverName=
webPath=
webUser=
webGroup=
staticCleanScript=
phpExecutable=
memoryLimit=
force=0

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:j:k:o:s:a:l:b:i:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    n) serverName=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    j) backendLocales=$(trim "$OPTARG");;
    k) backendThemes=$(trim "$OPTARG");;
    o) frontendLocales=$(trim "$OPTARG");;
    s) frontendThemes=$(trim "$OPTARG");;
    a) staticHashScript=$(trim "$OPTARG");;
    l) staticCleanScript=$(trim "$OPTARG");;
    b) phpExecutable=$(trim "$OPTARG");;
    i) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

if [[ -z "${serverName}" ]]; then
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

currentGroup=$(id -g -n)
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
    -n "${serverName}" \
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

    if [[ $(versionCompare "${magentoVersion}" "2.1.0") == 1 ]]; then
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
