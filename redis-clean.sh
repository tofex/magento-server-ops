#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  The host name of the Redis instance
  -p  The port of the Redis instance
  -d  The number of the database to clean
  -s  The password of the Redis instance (optional)

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

redisHost=
redisPort=
redisDatabase=
redisPassword=

while getopts ho:p:d:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) redisHost=$(trim "$OPTARG");;
    p) redisPort=$(trim "$OPTARG");;
    d) redisDatabase=$(trim "$OPTARG");;
    s) redisPassword=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${redisHost}" ]]; then
  echo "No Redis host specified!"
  exit 1
fi

if [[ -z "${redisPort}" ]]; then
  echo "No Redis port specified!"
  exit 1
fi

if [[ -z "${redisDatabase}" ]]; then
  echo "No Redis database specified!"
  exit 1
fi

if [[ -n "${redisHost}" ]] && [[ -n "${redisPort}" ]] && [[ -n "${redisDatabase}" ]]; then
  telnetAvailable=$(which telnet | wc -l)
  if [[ "${telnetAvailable}" -eq 1 ]]; then
    echo "Flushing Redis"
    if [[ -n "${redisPassword}" ]] && [[ "${redisPassword}" != "-" ]]; then
      ( sleep 1; echo "auth ${redisPassword}"; echo select "${redisDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisHost}" "${redisPort}" | cat
    else
      ( sleep 1; echo select "${redisDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisHost}" "${redisPort}" | cat
    fi
  else
    echo "Cannot flush Redis because telnet is not available"
    exit 1
  fi
fi
