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
  -q  Quiet mode

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
webPath=
webUser=
webGroup=
quiet=0

while getopts hn:w:u:g:t:v:p:z:x:y:q? option; do
  case "${option}" in
    h) usage; exit 1;;
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
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
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
  echo "Generating static files hash in path: ${webPath}"
fi

fileTypes=( css eot gif htc htm html ico jpg js less map otf png sass svg swf ttf webp woff woff2 )
excludePaths=( "./dev/*" "./pub/*" "./setup/*" "./status/*" "./update/*" "./vendor/astock/stock-api-libphp/test/*" "./vendor/astock/stock-api-libphp/test/*" "./vendor/braintree/braintree_php/tests/*" "./vendor/codeception/codeception/tests/*" "./vendor/container-interop/container-interop/docs/*" "./vendor/endroid/qr-code/assets/*" "./vendor/google/recaptcha/examples/*" "./vendor/guzzlehttp/ringphp/tests/*" "./vendor/magento/magento2-base/dev/tests/*" "./vendor/magento/module-catalog-import-export/Test/*" "./vendor/magento/magento2-functional-testing-framework/*" "./vendor/phpunit/php-code-coverage/*" "./vendor/squizlabs/php_codesniffer/*" "./vendor/tofex/jokkedk-webgrind/*" "./vendor/tubalmartin/cssmin/tests/*" "./vendor/zendframework/zend-config/doc/*" "./vendor/zendframework/zend-crypt/doc/*" "./vendor/zendframework/zend-di/doc/*" "./vendor/zendframework/zend-soap/doc/*" )

hashCommand="find . -type f \( -path '*/i18n/*'"

for fileType in "${fileTypes[@]}"; do
  hashCommand="${hashCommand} -o -iname '*.${fileType}'"
done

hashCommand="${hashCommand} \)"

for excludePath in "${excludePaths[@]}"; do
  hashCommand="${hashCommand} -not -path \"${excludePath}\""
done

hashCommand="${hashCommand} | sort -n | xargs -d '\n' md5sum | md5sum | awk '{print \$1}'"

cd "${webPath}"

oldIFS="${IFS}"
IFS=$'\n'
if [[ "${quiet}" == 1 ]]; then
  echo -n "${serverName}:"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "$hashCommand"
  else
    bash -c "$hashCommand"
  fi
else
  hash=$(bash -c "$hashCommand")
  echo "Static files hash: ${hash}"
fi
IFS="${oldIFS}"
