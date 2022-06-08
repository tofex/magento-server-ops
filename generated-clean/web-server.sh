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

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

cd "${webPath}"

if [[ -d var/di/ ]]; then
  diFiles=$(ls -A var/di/ | wc -l)
  if [[ "${diFiles}" -gt 0 ]]; then
    echo "Removing DI files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf var/di/*"
    else
      rm -rf var/di/*
    fi
  fi
fi

if [[ -d var/generation/ ]]; then
  generatedFiles=$(ls -A var/generation/ | wc -l)
  if [[ "${generatedFiles}" -gt 0 ]]; then
    echo "Removing generated code files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf var/generation/*"
    else
      rm -rf var/generation/*
    fi
  fi
fi

if [[ -d generated/code/ ]]; then
  generatedFiles=$(ls -A generated/code/ | wc -l)
  if [[ "${generatedFiles}" -gt 0 ]]; then
    echo "Removing generated code files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf generated/code/*"
    else
      rm -rf generated/code/*
    fi
  fi
fi

if [[ -d generated/metadata/ ]]; then
  generatedFiles=$(ls -A generated/metadata/ | wc -l)
  if [[ "${generatedFiles}" -gt 0 ]]; then
    echo "Removing generated meta data files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf generated/metadata/*"
    else
      rm -rf generated/metadata/*
    fi
  fi
fi
