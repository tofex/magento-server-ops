#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help        Show this message
  --webPath     Web path of Magento installation
  --webUser     Web user (optional)
  --webGroup    Web group (optional)
  --sharedPath  Shared path, default: shared
  --fileName    File to share
  --overwrite   Overwrite existing files (Optional)
  --revert      revert moving file to shared

Example: ${scriptName} --webPath /var/www/magento/htdocs/ --sharedPath /var/www/magento/shared/ --fileName app/etc/config.php --overwrite
EOF
}

webPath=
webUser=
webGroup=
sharedPath=
fileName=
overwrite=
revert=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
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

if [[ -z "${sharedPath}" ]]; then
  sharedPath="shared"
fi

if [[ -z "${fileName}" ]]; then
  echo "No file specified"
  exit 1
fi

if [[ -z "${overwrite}" ]]; then
  overwrite=0
fi

if [[ -z "${revert}" ]]; then
  revert=0
fi

webRoot=$(dirname "${webPath}")

webPathFileName="${webPath}/${fileName}"
webPathFilePath=$(dirname "${webPathFileName}")
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

  if [[ $(mount | grep " ${webPathFileName} " | wc -l) -gt 0 ]] || [[ $(mount | grep " ${webPathFilePath} " | wc -l) -gt 0 ]]; then
    echo "${webPathFileName} is mounted"
  elif [[ -L "${webPathFileName}" ]]; then
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
  if [[ $(mount | grep " ${webPathFileName} " | wc -l) -gt 0 ]] || [[ $(mount | grep " ${webPathFilePath} " | wc -l) -gt 0 ]]; then
    echo "${webPathFileName} is mounted"
  elif [[ -L "${webPathFileName}" ]]; then
    echo "Removing symlink at: ${webPathFileName}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "rm ${webPathFileName}"
    else
      rm "${webPathFileName}"
    fi

    echo "Moving file from: ${sharedPathFileName} to: ${webPathFileName}"
    if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
      sudo -H -u "${webUser}" bash -c "mv ${sharedPathFileName} ${webPathFileName}"
    else
      mv "${sharedPathFileName}" "${webPathFileName}"
    fi
  else
    echo "${webPathFileName} is not a symlink"
  fi
fi
