#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Path of deployment
  -u  Web user (optional)
  -g  Web group (optional)
  -a  Generated hash script
  -l  Generated code clean script
  -b  PHP executable (optional)
  -i  Memory limit (optional)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
serverName=
webPath=
webUser=
webGroup=
generatedCleanScript=
phpExecutable=
memoryLimit=
force=0

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:a:l:b:i:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    n) serverName=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    a) generatedHashScript=$(trim "$OPTARG");;
    l) generatedCleanScript=$(trim "$OPTARG");;
    b) phpExecutable=$(trim "$OPTARG");;
    i) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
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

if [[ -z "${generatedHashScript}" ]]; then
  echo "No generated hash script specified!"
  usage
  exit 1
fi

if [[ -z "${generatedCleanScript}" ]]; then
  echo "No generated clean script specified!"
  usage
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  echo "No code generation required"
else
  echo "Determining generated files hash in path: ${webPath}"
  generatedHash=$("${generatedHashScript}" \
    -n "${serverName}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -q)

  if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 1 ]]; then
    generateRequired=0
    if [[ ! -d var/di/ ]]; then
      echo "Generating required because no var/di was found"
      generateRequired=1
    else
      diFiles=$(ls -A var/di/ | wc -l)
      if [[ "${diFiles}" -eq 0 ]]; then
        echo "Generating required because var/di is emptry"
        generateRequired=1
      else
        if [[ ! -f var/generation_files_hash.txt ]]; then
          echo "Generating required because no previous generated files hash was found"
          generateRequired=1
        else
          echo "Reading previous generated files hash"
          previousGeneratedHash=$(cat var/generation_files_hash.txt)
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
    fi
  else
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
  fi

  if [[ "${generateRequired}" == 1 ]]; then
    "${generatedCleanScript}" \
      -w "${webPath}" \
      -u "${webUser}" \
      -g "${webGroup}"

    isSymlink=0

    if [[ -L generated ]]; then
      isSymlink=1
      symlinkPath=$(readlink -f generated)

      echo "Temporarily remove symlink from: ${symlinkPath} to: generated"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm generated"
      else
        rm generated
      fi

      if [[ -d generated ]]; then
        echo "Removing old generated directory"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf generated"
        else
          rm -rf generated
        fi
      fi
    fi

    echo "Compiling code in path: ${webPath}"
    if [[ -n "${memoryLimit}" ]]; then
      echo "Using memory limit: ${memoryLimit}"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "${phpExecutable} -dmemory_limit=${memoryLimit} bin/magento setup:di:compile 2>&1"
      else
        "${phpExecutable}" -dmemory_limit="${memoryLimit}" bin/magento setup:di:compile 2>&1
      fi
    else
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento setup:di:compile 2>&1"
      else
        "${phpExecutable}" bin/magento setup:di:compile 2>&1
      fi
    fi

    if [[ $(versionCompare "${magentoVersion}" "2.2.0") == 1 ]]; then
      echo "${generatedHash}" > var/generation_files_hash.txt
    else
      echo "${generatedHash}" > generated/metadata/files_hash.txt
    fi

    if [[ "${isSymlink}" == 1 ]]; then
      if [[ -d "${symlinkPath}/code" ]]; then
        echo "Removing previous code folder"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf ${symlinkPath}/code"
        else
          rm -rf "${symlinkPath}/code"
        fi
      fi

      if [[ -d "${symlinkPath}/metadata" ]]; then
        echo "Removing previous metadata folder"
        if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
          sudo -H -u "${webUser}" bash -c "rm -rf ${symlinkPath}/metadata"
        else
          rm -rf "${symlinkPath}/metadata"
        fi
      fi

      echo "Moving generated code folder to: ${symlinkPath}/code"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mv generated/code ${symlinkPath}/code"
      else
        mv generated/code "${symlinkPath}/code"
      fi

      echo "Moving generated metadata folder to: ${symlinkPath}/metadata"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "mv generated/metadata ${symlinkPath}/metadata"
      else
        mv generated/metadata "${symlinkPath}/metadata"
      fi

      echo "Removing generated directory"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "rm -rf generated"
      else
        rm -rf generated
      fi

      echo "Creating symlink from: ${symlinkPath} to: generated"
      if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
        sudo -H -u "${webUser}" bash -c "ln -s ${symlinkPath} generated"
      else
        ln -s "${symlinkPath}" generated
      fi
    fi
  fi
fi
