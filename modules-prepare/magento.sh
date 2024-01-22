#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Path of deployment
  -u  Web user (optional)
  -g  Web group (optional)
  -s  Module diff script
  -l  Generated code clean script
  -a  Static content clean script
  -b  PHP executable (optional)

Example: ${scriptName} -w /var/www/magento/htdocs
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
webPath=
webUser=
webGroup=
moduleDiffScript=
generatedCleanScript=
staticCleanScript=
phpExecutable=

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:s:l:a:b:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
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
    s) moduleDiffScript=$(trim "$OPTARG");;
    l) generatedCleanScript=$(trim "$OPTARG");;
    a) staticCleanScript=$(trim "$OPTARG");;
    b) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ $(versionCompare "${magentoVersion}" "2.0.0") == 1 ]]; then
  echo "No preparing for Magento 1 required"
  exit 0
fi

if [[ $(versionCompare "${magentoVersion}" "19.1.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "19.1.0") == 2 ]]; then
  echo "No preparing for OpenMage required"
  exit 0
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

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${moduleDiffScript}" ]]; then
  echo "No module diff script specified!"
  usage
  exit 1
fi

if [[ -z "${generatedCleanScript}" ]]; then
  echo "No generated clean script specified!"
  usage
  exit 1
fi

if [[ -z "${staticCleanScript}" ]]; then
  echo "No static clean script specified!"
  usage
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

echo "Checking missing modules in web path: ${webPath}"
missingModules=( $("${moduleDiffScript}" \
  -w "${webPath}" \
  -u "${webUser}" \
  -g "${webGroup}" \
  -m \
  -q) )
if [[ "${#missingModules[@]}" -gt 0 ]]; then
  echo "Found missing module(s): ${missingModules[*]}"
  "${generatedCleanScript}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}"
  "${staticCleanScript}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}"
else
  echo "No missing modules to remove"
fi

echo "Checking unknown modules in web path: ${webPath}"
unknownModules=( $("${moduleDiffScript}" \
  -w "${webPath}" \
  -u "${webUser}" \
  -g "${webGroup}" \
  -k \
  -q) )
if [[ "${#unknownModules[@]}" -gt 0 ]]; then
  cd "${webPath}"
  echo "Activate module(s): ${unknownModules[*]}"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento module:enable ${unknownModules[*]}"
  else
    bash -c "${phpExecutable} bin/magento module:enable ${unknownModules[*]}"
  fi
else
  echo "No unknown modules to activate"
fi
