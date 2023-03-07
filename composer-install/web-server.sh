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
  -i  Memory limit (optional)
  -c  Composer script (optional)

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
memoryLimit=
composerScript=

while getopts hn:w:u:g:t:v:p:z:x:y:b:i:c:? option; do
  case ${option} in
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
    i) memoryLimit=$(trim "$OPTARG");;
    c) composerScript=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

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

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

composerBinary=$(which composer)

cd "${webPath}"

echo "Installing composer project in path: ${webPath}"
if [[ -n "${memoryLimit}" ]]; then
  echo "Using memory limit: ${memoryLimit}"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    if [[ -n "${composerScript}" ]]; then
      sudo -H -u "${webUser}" bash -c "COMPOSER_MEMORY_LIMIT=${memoryLimit} ${composerScript} install --prefer-dist --no-dev"
    else
      sudo -H -u "${webUser}" bash -c "COMPOSER_MEMORY_LIMIT=${memoryLimit} ${phpExecutable} ${composerBinary} install --prefer-dist --no-dev"
    fi
  else
    if [[ -n "${composerScript}" ]]; then
      COMPOSER_MEMORY_LIMIT="${memoryLimit}" "${composerScript}" install --prefer-dist --no-dev
    else
      COMPOSER_MEMORY_LIMIT="${memoryLimit}" "${phpExecutable}" "${composerBinary}" install --prefer-dist --no-dev
    fi
  fi
else
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    if [[ -n "${composerScript}" ]]; then
      sudo -H -u "${webUser}" bash -c "${composerScript} install --prefer-dist --no-dev"
    else
      sudo -H -u "${webUser}" bash -c "${phpExecutable} ${composerBinary} install --prefer-dist --no-dev"
    fi
  else
    if [[ -n "${composerScript}" ]]; then
      "${composerScript}" install --prefer-dist --no-dev
    else
      "${phpExecutable}" "${composerBinary}" install --prefer-dist --no-dev
    fi
  fi
fi
