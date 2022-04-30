#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -o  Host name
  -p  Port
  -u  User name
  -s  Password
  -n  Database name

Example: ${scriptName} -m 2.3.7 -o localhost -p 3306 -u magento_user -p magento_pass -n magento_db
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
host=
port=
user=
password=
name=

while getopts hm:o:p:u:s:n:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    n) name=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${host}" ]]; then
  echo "No database host specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${user}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${password}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${name}" ]]; then
  echo "No database name specified!"
  exit 1
fi

echo "Removing database sessions"
export MYSQL_PWD="${password}"
if [[ ${magentoVersion:0:1} == "1" ]]; then
  mysql -h"${host}" -P"${port}" -u"${user}" "${name}" -e "DELETE FROM core_session;"
else
  mysql -h"${host}" -P"${port}" -u"${user}" "${name}" -e "DELETE FROM session;"
fi
