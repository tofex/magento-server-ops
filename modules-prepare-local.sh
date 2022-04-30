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
  -e  PHP executable (optional)

Example: ${scriptName} -p /var/www/magento/releases/12345 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

path=
webUser=
webGroup=
phpExecutable="php"

while getopts hp:u:g:e:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) path=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    e) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${path}" ]]; then
  echo "No deploy path specified!"
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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Checking missing modules in path: ${path}"
missingModules=( $("${currentPath}/../ops/modules-diff-local.sh" -w "${path}" -u "${webUser}" -g "${webGroup}" -m -q) )
if [[ "${#missingModules[@]}" -gt 0 ]]; then
  echo "Found missing module(s): ${missingModules[*]}"
  "${currentPath}/../ops/generated-clean.sh"
  "${currentPath}/../ops/static-clean.sh"
else
  echo "No missing modules to remove"
fi

echo "Checking unknown modules in path: ${path}"
unknownModules=( $("${currentPath}/../ops/modules-diff-local.sh" -w "${path}" -u "${webUser}" -g "${webGroup}" -n -q) )
if [[ "${#unknownModules[@]}" -gt 0 ]]; then
  cd "${path}"
  echo "Activate module(s): ${unknownModules[*]}"
  if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
    sudo -H -u "${webUser}" bash -c "${phpExecutable} bin/magento module:enable ${unknownModules[*]}"
  else
    bash -c "${phpExecutable} bin/magento module:enable ${unknownModules[*]}"
  fi
else
  echo "No unknown modules to activate"
fi
