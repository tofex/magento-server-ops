#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -w  Web path of Magento installation
  -u  Web user (optional)
  -g  Web group (optional)
  -m  Memory limit (optional)
  -e  PHP executable (optional)
  -f  Force (optional)

Example: ${scriptName} -v 2.4.2 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
webPath=
webUser=
webGroup=
memoryLimit=
phpExecutable="php"
force=0

while getopts hv:w:u:g:n:m:e:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    m) memoryLimit=$(trim "$OPTARG");;
    e) phpExecutable=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
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

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No code generation required"
else
  echo "Determining generated files hash in path: ${webPath}"
  generatedHash=$("${currentPath}/generated-hash-local.sh" -w "${webPath}" -u "${webUser}" -g "${webGroup}" -q)

  generateRequired=0
  if [[ ! -f generated/metadata/frontend.php ]]; then
    echo "Generating required because no generated/metadata/frontend.php was found"
    generateRequired=1
  else
    if [[ ! -f generated/metadata/files_hash.txt ]]; then
      echo "Generating required because no previous generated files hash was found"
      generateRequired=1
    else
      echo "Reading previous generated files hash"
      previousGeneratedHash=$(cat generated/metadata/files_hash.txt)
      if [[ "${generatedHash}" != "${previousGeneratedHash}" ]]; then
        echo "Generating required because previous generated hash is different"
        generateRequired=1
      else
        if [[ "${force}" == 1 ]]; then
          echo "Generating required because of force mode while previous generated hash matches"
          generateRequired=1
        else
          echo "No generating required because previous generated hash matches"
        fi
      fi
    fi
  fi

  if [[ "${generateRequired}" == 1 ]]; then
    "${currentPath}/../ops/generated-clean-local.sh" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"

    isSymlink=0

    if [[ -L generated ]]; then
      isSymlink=1
      symlinkPath=$(readlink -f generated)

      echo "Temporarily remove symlink from: ${symlinkPath} to: generated"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm generated"
      else
        rm generated
      fi

      if [[ -d generated ]]; then
        echo "Removing old generated directory"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf generated"
        else
          rm -rf generated
        fi
      fi
    fi

    echo "Compiling code in path: ${webPath}"
    if [[ -n "${memoryLimit}" ]]; then
      echo "Using memory limit: ${memoryLimit}"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} bin/magento setup:di:compile"
      else
        "${phpExecutable}" -dmemory_limit="${memoryLimit}" bin/magento setup:di:compile
      fi
    else
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento setup:di:compile"
      else
        "${phpExecutable}" bin/magento setup:di:compile
      fi
    fi

    echo "${generatedHash}" > generated/metadata/files_hash.txt

    if [[ "${isSymlink}" == 1 ]]; then
      if [[ -d "${symlinkPath}/code" ]]; then
        echo "Removing previous code folder"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf ${symlinkPath}/code"
        else
          rm -rf "${symlinkPath}/code"
        fi
      fi

      if [[ -d "${symlinkPath}/metadata" ]]; then
        echo "Removing previous metadata folder"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf ${symlinkPath}/metadata"
        else
          rm -rf "${symlinkPath}/metadata"
        fi
      fi

      echo "Moving generated code folder to: ${symlinkPath}/code"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mv generated/code ${symlinkPath}/code"
      else
        mv generated/code "${symlinkPath}/code"
      fi

      echo "Moving generated metadata folder to: ${symlinkPath}/metadata"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mv generated/metadata ${symlinkPath}/metadata"
      else
        mv generated/metadata "${symlinkPath}/metadata"
      fi

      echo "Removing generated directory"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm -rf generated"
      else
        rm -rf generated
      fi

      echo "Creating symlink from: ${symlinkPath} to: generated"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ ${webGroup} != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "ln -s ${symlinkPath} generated"
      else
        ln -s "${symlinkPath}" generated
      fi
    fi
  fi
fi
