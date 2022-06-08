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
  -s  shared path
  -f  file to share
  -o  Overwrite existing files (Optional)
  -r  revert moving file to shared

Example: ${scriptName} -w /var/www/magento/htdocs/ -s /var/www/magento/shared/ -f app/etc/config.php -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
webUser=
webGroup=
sharedPath=
fileName=
overwrite=0
revert=0

while getopts hn:w:u:g:t:v:p:z:x:y:s:f:or? option; do
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
    s) sharedPath=$(trim "$OPTARG");;
    f) fileName=$(trim "$OPTARG");;
    o) overwrite=1;;
    r) revert=1;;
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
  usage
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 0
fi

if [[ -z "${sharedPath}" ]]; then
  echo "No shared path specified"
  exit 1
fi

if [[ -z "${fileName}" ]]; then
  echo "No file specified"
  exit 1
fi

webRoot=$(dirname "${webPath}")

webPathFileName="${webPath}/${fileName}"
sharedPathFileName="${webRoot}/${sharedPath}/${fileName}"
sharedPathFilePath=$(dirname "${sharedPathFileName}")

if [[ "${revert}" == 0 ]]; then
  if [[ ! -d "${sharedPathFilePath}" ]]; then
    echo "Creating shared path: ${sharedPathFilePath}"
    set +e
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      if ! sudo -H -u "${webUser}" bash -c "mkdir -p ${sharedPathFilePath} 2>/dev/null"; then
        sudo -H -u "${webUser}" bash -c "sudo mkdir -p ${sharedPathFilePath} 2>/dev/null"
        sudo -H -u "${webUser}" bash -c "sudo chown ${currentUser}:${currentGroup} ${sharedPathFilePath} 2>/dev/null"
      fi
    else
      if ! mkdir -p "${sharedPathFilePath}" 2>/dev/null; then
        sudo mkdir -p "${sharedPathFilePath}" 2>/dev/null
        sudo chown "${currentUser}":"${currentGroup}" "${sharedPathFilePath}" 2>/dev/null
      fi
    fi
    set -e
  fi

  if [[ -L "${webPathFileName}" ]]; then
    echo "${webPathFileName} is already a symlink"
  else
    if [[ -e "${sharedPathFileName}" ]] && [[ "${overwrite}" == 1 ]]; then
      echo "Removing previous files at: ${sharedPathFileName}"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm -rf ${sharedPathFileName}"
      else
        rm -rf "${sharedPathFileName}"
      fi
    fi

    if [[ -e "${webPathFileName}" ]]; then
      echo "Moving file from: ${webPathFileName} to: ${sharedPathFileName}"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mv ${webPathFileName} ${sharedPathFileName}"
      else
        result=$(mv "${webPathFileName}" "${sharedPathFileName}" 2>/dev/null && echo "1" || echo "0")
        if [[ ${result} -eq 0 ]]; then
          sudo mv "${webPathFileName}" "${sharedPathFileName}"
          sudo chown "${webUser}":"${webGroup}" "${sharedPathFileName}"
        fi
      fi
    fi

    echo "Linking file from: ${sharedPathFileName} to: ${webPathFileName}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "ln -s ${sharedPathFileName} ${webPathFileName}"
    else
      ln -s "${sharedPathFileName}" "${webPathFileName}"
    fi
  fi
else
  if [[ -L "${webPathFileName}" ]]; then
    echo "Removing symlink at: ${webPathFileName}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm ${webPathFileName}"
    else
      rm "${webPathFileName}"
    fi

    echo "Moving file from: ${sharedPathFileName} to: ${webPathFileName}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      mv "${sharedPathFileName}" "${webPathFileName}"
    else
      sudo -H -u "${webUser}" bash -c "mv ${sharedPathFileName} ${webPathFileName}"
    fi
  else
    echo "${webPathFileName} is not a symlink"
  fi
fi
