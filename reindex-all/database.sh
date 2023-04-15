#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --magentoVersion    Magento version
  --databaseHost      Database host name, default: localhost
  --databasePort      Database port, default: 3306
  --databaseUser      Database user name
  --databasePassword  Database Password
  --databaseName      Database name

Example: ${scriptName} --magentoVersion 2.3.7 --databaseUser magento_user --databasePassword magento_pass --databaseName magento_db
EOF
}

magentoVersion=
databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  databaseHost="127.0.0.1"
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

echo "Resetting indexer status"

if [[ ${magentoVersion:0:1} == "1" ]]; then
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE index_process SET status = 'require_reindex' WHERE status = 'working';"
else
  mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -e "UPDATE indexer_state SET status = 'invalid' WHERE status = 'working';"
fi
