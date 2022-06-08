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
  -q  Quiet

Example: ${scriptName} -m 2.3.7 -u magento_user -p magento_pass -b magento_db
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
quiet=0

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:q? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    u) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    b) databaseName=$(trim "$OPTARG");;
    t) ;;
    v) ;;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
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

if [[ ${magentoVersion:0:1} == "2" ]]; then
  export MYSQL_PWD="${databasePassword}"

  if [[ "${quiet}" == 0 ]]; then
    echo "Determining required frontend locales"
  fi

  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(value) FROM core_config_data WHERE path = \"general/locale/code\";"
fi
