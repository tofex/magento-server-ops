#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name
  -w  Web path of Magento installation
  -u  Web user (optional)
  -g  Web group (optional)
  -q  Quiet mode

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
webPath=
webUser=
webGroup=
quiet=0

while getopts hn:w:u:g:t:v:p:z:x:y:q? option; do
  case "${option}" in
    h) usage; exit 1;;
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
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
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
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Generating generated files hash in path: ${webPath}"
fi

filePatterns=( "di.xml" "extension_attributes.xml" "*.php" )
excludePaths=( "./dev/*" "./generated/*" "./pub/*" "./setup/*" "./status/*" "./update/*" )

hashCommand="find . -type f \("

first=1
for filePattern in "${filePatterns[@]}"; do
  if [[ "${first}" == 0 ]]; then
    hashCommand="${hashCommand}-o"
  fi
  hashCommand="${hashCommand} -iname '${filePattern}' "
  first=0
done

hashCommand="${hashCommand}\) ! -iname 'autoload.php' ! -iname 'autoload_*.php'"

for excludePath in "${excludePaths[@]}"; do
  hashCommand="${hashCommand} -not -path \"${excludePath}\""
done

hashCommand="${hashCommand} | sort -n | xargs -d '\n' md5sum | md5sum | awk '{print \$1}'"

cd "${webPath}"

oldIFS="${IFS}"
IFS=$'\n'
if [[ "${quiet}" == 1 ]]; then
  echo -n "${serverName}:"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "$hashCommand"
  else
    bash -c "$hashCommand"
  fi
else
  hash=$(bash -c "$hashCommand")
  echo "Generated files hash: ${hash}"
fi
IFS="${oldIFS}"
