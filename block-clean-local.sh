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

while getopts hw:u:g:? option; do
  case ${option} in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentUser=$(whoami)
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup=$(id -g -n)
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 1
fi

cd "${webPath}"

if [[ -f bin/magento ]]; then
  echo "Cleaning block cache"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "bin/magento cache:clean block_html"
  else
    bin/magento cache:clean block_html
  fi
fi
