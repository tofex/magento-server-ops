#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --databaseHost      Host of database, default: localhost
  --databasePort      Port of database, default: 3306
  --databaseUser      User of database
  --databasePassword  Password of database
  --databaseName      Name of database
  --quiet             Quiet mode, list only versions

Example: ${scriptName} --databaseUser magento_user --databasePassword magento_pass --databaseName magento_db
EOF
}

databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
quiet=0

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
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

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module versions in database"
fi

export MYSQL_PWD="${databasePassword}"

databaseModules=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT CONCAT(module, \":\", schema_version) FROM setup_module ORDER BY module ASC;") )

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#databaseModules[@]} modules"
fi

if [[ "${#databaseModules[@]}" -gt 0 ]]; then
  if [[ "${quiet}" == 1 ]]; then
    echo "${databaseModules[@]}"
  else
    printf "%s\n" "${databaseModules[@]}"
  fi
fi
