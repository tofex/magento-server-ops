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
  -o  Database hostname, default: localhost
  -p  Port of the database, default: 3306
  -r  Database user
  -s  Database password
  -n  Database name
  -m  Memory limit (optional)
  -e  PHP executable (optional)

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
databaseHost="localhost"
databasePort="3306"
databaseUser=
databasePassword=
databaseName=
memoryLimit=
phpExecutable="php"

while getopts hv:w:u:g:o:p:r:n:s:n:m:e:? option; do
  case ${option} in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    r) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    n) databaseName=$(trim "$OPTARG");;
    m) memoryLimit=$(trim "$OPTARG");;
    e) phpExecutable=$(trim "$OPTARG");;
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

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

if [[ -n "${memoryLimit}" ]]; then
  "${currentPath}/generate-code-local.sh" \
    -v "${magentoVersion}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -m "${memoryLimit}" \
    -e "${phpExecutable}"
else
  "${currentPath}/generate-code-local.sh" \
    -v "${magentoVersion}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -e "${phpExecutable}"
fi

if [[ -n "${memoryLimit}" ]]; then
  "${currentPath}/generate-static-local.sh" \
    -v "${magentoVersion}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -r "${databaseUser}" \
    -s "${databasePassword}" \
    -n "${databaseName}" \
    -m "${memoryLimit}" \
    -e "${phpExecutable}"
else
  "${currentPath}/generate-static-local.sh" \
    -v "${magentoVersion}" \
    -w "${webPath}" \
    -u "${webUser}" \
    -g "${webGroup}" \
    -o "${databaseHost}" \
    -p "${databasePort}" \
    -r "${databaseUser}" \
    -s "${databasePassword}" \
    -n "${databaseName}" \
    -e "${phpExecutable}"
fi
