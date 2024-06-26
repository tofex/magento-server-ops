#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -o  Database hostname, default: localhost
  -p  Port of the database, default: 3306
  -u  Database user
  -s  Database password
  -b  Database name

Example: ${scriptName} -m 2.4.2 -u user -s password -b database
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

while getopts hm:e:d:r:c:o:p:u:s:b:t:v:? option; do
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

export MYSQL_PWD="${databasePassword}"

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  hostList=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT CONCAT(config.value, '|', IF(config.scope='default','default',IF(config.scope='websites','website','store')), '|', IF(config.scope='default','default',IF(config.scope='websites',core_website.code,core_store.code))) FROM core_config_data config LEFT JOIN core_website ON core_website.website_id = config.scope_id AND config.scope = 'websites' LEFT JOIN core_store ON core_store.store_id = config.scope_id AND config.scope = 'stores' WHERE config.path LIKE 'web/%secure/base_url' AND config.value LIKE 'http%' AND NOT EXISTS (SELECT 1 FROM core_config_data config1 WHERE config.value = config1.value AND config.scope_id < config1.scope_id) GROUP BY config.scope, config.scope_id, config.value ORDER BY config.scope_id;") )
else
  hostList=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT CONCAT(config.value, '|', IF(config.scope='default','default',IF(config.scope='websites','website','store')), '|', IF(config.scope='default','default',IF(config.scope='websites',store_website.code,store.code))) FROM core_config_data config LEFT JOIN store_website ON store_website.website_id = config.scope_id AND config.scope = 'websites' LEFT JOIN store ON store.store_id = config.scope_id AND config.scope = 'stores' WHERE config.path LIKE 'web/%secure/base_url' AND config.value LIKE 'http%' AND NOT EXISTS (SELECT 1 FROM core_config_data config1 WHERE config.value = config1.value AND config.scope_id < config1.scope_id) GROUP BY config.scope, config.scope_id, config.value ORDER BY config.scope_id;") )
fi

for host in "${hostList[@]}"; do
  hostUrl=$(echo "${host}" | cut -d\| -f1)
  hostScope=$(echo "${host}" | cut -d\| -f2)
  hostCode=$(echo "${host}" | cut -d\| -f3)
  hostName=$(echo "${hostUrl}" | awk -F/ '{print $3}')
  echo "${hostName}:${hostScope}:${hostCode}"
done
