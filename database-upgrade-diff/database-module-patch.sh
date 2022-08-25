#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Host databaseName, default: localhost
  -p  Port, default: 3306
  -u  User databaseName
  -s  Password
  -b  Database databaseName
  -q  Quiet mode, list only patches

Example: ${scriptName} -u magento_user -p magento_pass -b magento_db
EOF
}

trim()
{
  echo -n "$1" | xargs
}

databaseHost=
databasePort=
databaseUser=
databasePassword=
databaseName=
quiet=0

while getopts ho:p:u:s:b:t:v:q? option; do
  case "${option}" in
    h) usage; exit 1;;
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
  echo "Determining patches in database"
fi

export MYSQL_PWD="${databasePassword}"

databasePatchClasses=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(patch_name) FROM patch_list ORDER BY patch_name ASC;") )

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#databasePatchClasses[@]} patches"
fi

if [[ "${#databasePatchClasses[@]}" -gt 0 ]]; then
  echo "${databasePatchClasses[@]}"
fi
