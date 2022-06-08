#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path of Magento installation
  -b  PHP executable (optional)
  -q  Quiet mode, list only changes

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
phpExecutable=
quiet=0

while getopts hn:w:u:g:t:v:p:z:x:y:b:q? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    b) phpExecutable=$(trim "$OPTARG");;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining inactive modules in path: ${webPath}"
fi

inactiveModuleNames=( $(bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {if (\\\$config['modules'][\\\$moduleName] == 0) {echo \\\"\\\$moduleName\n\\\";}}\" | sort -n") )

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#inactiveModuleNames[@]} inactive modules"
fi

if [[ "${#inactiveModuleNames[@]}" -gt 0 ]]; then
  echo "${inactiveModuleNames[@]}"
fi
