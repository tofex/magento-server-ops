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
  case "${option}" in
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
  exit 0
fi

cd "${webPath}"

if [[ -d var/debug/ ]]; then
  debugFiles=$(ls -A var/debug/ | wc -l)
  if [[ "${debugFiles}" -gt 0 ]]; then
    echo "Removing debug files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "find var/debug/ -type f -delete"
      sudo -H -u "${webUser}" bash -c "rm -rf var/debug/*"
    else
      find var/debug/ -type f -delete
      rm -rf var/debug/*
    fi
  fi
fi

if [[ -d var/log/ ]]; then
  logFiles=$(ls -A var/log/ | wc -l)
  if [[ "${logFiles}" -gt 0 ]]; then
    echo "Removing log files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "find var/log/ -type f -delete"
      sudo -H -u "${webUser}" bash -c "rm -rf var/log/*"
    else
      find var/log/ -type f -delete
      rm -rf var/log/*
    fi
  fi
fi

if [[ -d var/report/ ]]; then
  reportFiles=$(ls -A var/report/ | wc -l)
  if [[ "${reportFiles}" -gt 0 ]]; then
    echo "Removing report files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "find var/report/ -type f -delete"
      sudo -H -u "${webUser}" bash -c "rm -rf var/report/*"
    else
      find var/report/ -type f -delete
      rm -rf var/report/*
    fi
  fi
fi
