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
  -c  PHP executable (optional)

Example: ${scriptName} -w /var/www/magento/htdocs
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
moduleDiffScript=
generatedCleanScript=
staticCleanScript=
phpExecutable=

while getopts hm:e:d:r:w:u:g:t:v:p:z:x:y:s:l:a:c:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
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
    c) phpExecutable=$(trim "$OPTARG");;
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

echo "Checking missing modules in webPath: ${webPath}"
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

echo "Checking unknown modules in webPath: ${webPath}"
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
