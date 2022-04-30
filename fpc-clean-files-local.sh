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

if [[ -d var/full_page_cache/ ]]; then
  fullPageCacheFiles=$(ls -A var/full_page_cache/ | wc -l)
  if [[ "${fullPageCacheFiles}" -gt 0 ]]; then
    echo "Removing full page cache files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf var/full_page_cache/*"
    else
      rm -rf var/full_page_cache/*
    fi
  fi
fi

if [[ -d var/page_cache/ ]]; then
  fullPageCacheFiles=$(ls -A var/page_cache/ | wc -l)
  if [[ "${fullPageCacheFiles}" -gt 0 ]]; then
    echo "Removing full page cache files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf var/page_cache/*"
    else
      rm -rf var/page_cache/*
    fi
  fi
fi
