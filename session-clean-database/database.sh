#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -o  Host name, default: localhost
  -p  Port, default: 3306
  -u  User name
  -s  Password
  -b  Database name

Example: ${scriptName} -m 2.3.7 -u magento_user -p magento_pass -b magento_db
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

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    o) host=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    b) name=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${host}" ]]; then
  host="localhost"
fi

if [[ -z "${port}" ]]; then
  port="3306"
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

export MYSQL_PWD="${password}"

echo "Removing database sessions"

if [[ ${magentoVersion:0:1} == "1" ]]; then
  mysql -h"${host}" -P"${port}" -u"${user}" "${name}" -e "DELETE FROM core_session;"
else
  mysql -h"${host}" -P"${port}" -u"${user}" "${name}" -e "DELETE FROM session;"
fi
