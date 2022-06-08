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

Example: ${scriptName} -f
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=

while getopts hn:w:u:g:t:v:p:z:x:y:? option; do
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
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
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

cd "${webPath}"

if [[ -d media/catalog/product/cache/ ]]; then
  productFiles=$(ls -A media/catalog/product/cache/ | wc -l)
  if [[ "${productFiles}" -gt 0 ]]; then
    echo "Removing generated product image files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf media/catalog/product/cache/*"
    else
      rm -rf media/catalog/product/cache/*
    fi
  fi
fi

if [[ -d pub/media/catalog/product/cache/ ]]; then
  productFiles=$(ls -A pub/media/catalog/product/cache/ | wc -l)
  if [[ "${productFiles}" -gt 0 ]]; then
    echo "Removing generated product image files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf pub/media/catalog/product/cache/*"
    else
      rm -rf pub/media/catalog/product/cache/*
    fi
  fi
fi
