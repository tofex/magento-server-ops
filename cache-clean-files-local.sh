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
  exit 0
fi

cd "${webPath}"

if [[ -d var/cache/ ]]; then
  cacheFiles=$(ls -A var/cache/ | wc -l)
  if [[ "${cacheFiles}" -gt 0 ]]; then
    echo "Removing cache files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      result=$(sudo -H -u "${webUser}" bash -c "rm -rf var/cache/*" 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        echo "Cache cleaning not successful: Waiting one second"
        sleep 1
        result2=$(sudo -H -u "${webUser}" bash -c "rm -rf var/cache/*" 2>/dev/null && echo "1" || echo "0")
        if [[ "${result2}" -eq 0 ]]; then
          echo "Cache cleaning not successful: Waiting three seconds"
          sleep 3
          sudo -H -u "${webUser}" bash -c "rm -rf var/cache/*"
        fi
      fi
    else
      result=$(rm -rf var/cache/* 2>/dev/null && echo "1" || echo "0")
      if [[ "${result}" -eq 0 ]]; then
        echo "Cache cleaning not successful: Waiting one second"
        sleep 1
        result2=$(rm -rf var/cache/* 2>/dev/null && echo "1" || echo "0")
        if [[ "${result2}" -eq 0 ]]; then
          echo "Cache cleaning not successful: Waiting three seconds"
          sleep 3
          rm -rf var/cache/*
        fi
      fi
    fi
  fi
fi

if [[ -d /tmp ]]; then
  zendFiles=$(ls -A /tmp | grep ^zend | wc -l)
  if [[ "${zendFiles}" -gt 0 ]]; then
    echo "Removing Zend cache files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      if [[ $(sudo -H -u "${webUser}" bash -c "SUDO_ASKPASS=/bin/false sudo -A whoami 2>&1") == "root" ]]; then
        sudo -H -u "${webUser}" bash -c "sudo rm -rf /tmp/zend*"
      else
        sudo -H -u "${webUser}" bash -c "rm -rf /tmp/zend*"
      fi
    else
      if [[ $(SUDO_ASKPASS=/bin/false sudo -A whoami 2>&1) == "root" ]]; then
        sudo rm -rf /tmp/zend*
      else
        rm -rf /tmp/zend*
      fi
    fi
  fi
fi
