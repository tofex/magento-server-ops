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

if [[ -d var/view_preprocessed/ ]]; then
  viewPreprocessedFiles=$(ls -A var/view_preprocessed/ | wc -l)
  if [[ "${viewPreprocessedFiles}" -gt 0 ]]; then
    echo "Removing view preprocessed files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf var/view_preprocessed/*"
    else
      rm -rf var/view_preprocessed/*
    fi
  fi
fi

if [[ -d media/css/ ]]; then
  cssFiles=$(ls -A media/css/ | wc -l)
  if [[ "${cssFiles}" -gt 0 ]]; then
    echo "Removing generated CSS files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf media/css/*"
    else
      rm -rf media/css/*
    fi
  fi
fi

if [[ -d media/css_secure/ ]]; then
  secureCssFiles=$(ls -A media/css_secure/ | wc -l)
  if [[ "${secureCssFiles}" -gt 0 ]]; then
    echo "Removing generated secure CSS files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf media/css_secure/*"
    else
      rm -rf media/css_secure/*
    fi
  fi
fi

if [[ -d media/js/ ]]; then
  jsFiles=$(ls -A media/js/ | wc -l)
  if [[ "${jsFiles}" -gt 0 ]]; then
    echo "Removing generated JavaScript files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf media/js/*"
    else
      rm -rf media/js/*
    fi
  fi
fi

if [[ -d media/tmp/ ]]; then
  tmpFiles=$(ls -A media/tmp/ | wc -l)
  if [[ "${tmpFiles}" -gt 0 ]]; then
    echo "Removing temporary media files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf media/tmp/*"
    else
      rm -rf media/tmp/*
    fi
  fi
fi

if [[ -d pub/static/_cache/ ]]; then
  staticFiles=$(ls -A pub/static/_cache/ | wc -l)
  if [[ "${staticFiles}" -gt 0 ]]; then
    echo "Removing static cache files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf pub/static/_cache/*"
    else
      rm -rf pub/static/_cache/*
    fi
  fi
fi

if [[ -d pub/static/adminhtml/ ]]; then
  staticFiles=$(ls -A pub/static/adminhtml/ | wc -l)
  if [[ "${staticFiles}" -gt 0 ]]; then
    echo "Removing static adminhtml files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf pub/static/adminhtml/*"
    else
      rm -rf pub/static/adminhtml/*
    fi
  fi
fi

if [[ -d pub/static/frontend/ ]]; then
  staticFiles=$(ls -A pub/static/frontend/ | wc -l)
  if [[ "${staticFiles}" -gt 0 ]]; then
    echo "Removing static frontend files"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm -rf pub/static/frontend/*"
    else
      rm -rf pub/static/frontend/*
    fi
  fi
fi

if [[ -f pub/static/deployed_version.txt ]]; then
  echo "Removing static deployed version file"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "rm -rf pub/static/deployed_version.txt"
  else
    rm -rf pub/static/deployed_version.txt
  fi
fi

if [[ -f pub/static/files_hash.txt ]]; then
  echo "Removing static hash file"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "rm -rf pub/static/files_hash.txt"
  else
    rm -rf pub/static/files_hash.txt
  fi
fi
