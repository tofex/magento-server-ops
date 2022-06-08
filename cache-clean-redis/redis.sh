#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  The redisHost name of the Redis instance
  -p  The redisPort of the Redis instance
  -s  The redisPassword of the Redis instance (optional)
  -b  The number of the redisDatabase to clean

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

redisHost=
redisPort=
redisPassword=
redisDatabase=

while getopts ho:p:s:b:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
    o) redisHost=$(trim "$OPTARG");;
    p) redisPort=$(trim "$OPTARG");;
    s) redisPassword=$(trim "$OPTARG");;
    b) redisDatabase=$(trim "$OPTARG");;
    v) ;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${redisHost}" ]]; then
  echo "No Redis redisHost specified!"
  exit 1
fi

if [[ -z "${redisPort}" ]]; then
  echo "No Redis redisPort specified!"
  exit 1
fi

if [[ -z "${redisDatabase}" ]]; then
  echo "No Redis redisDatabase specified!"
  exit 1
fi

if [[ -n "${redisHost}" ]] && [[ -n "${redisPort}" ]] && [[ -n "${redisDatabase}" ]]; then
  redisCliAvailable=$(which redis-cli | wc -l)
  telnetAvailable=$(which telnet | wc -l)
  if [[ "${redisCliAvailable}" -eq 1 ]]; then
    echo "Flushing Redis using redis-cli"
    if [[ -n "${redisPassword}" ]] && [[ "${redisPassword}" != "-" ]]; then
      REDISCLI_AUTH="${redisPassword}" redis-cli -h "${redisHost}" -p "${redisPort}" -n "${redisDatabase}" FLUSHDB
    else
      redis-cli -h "${redisHost}" -p "${redisPort}" -n "${redisDatabase}" FLUSHDB
    fi
  elif [[ "${telnetAvailable}" -eq 1 ]]; then
    echo "Flushing Redis using telnet"
    if [[ -n "${redisPassword}" ]] && [[ "${redisPassword}" != "-" ]]; then
      ( sleep 1; echo "auth ${redisPassword}"; echo select "${redisDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisHost}" "${redisPort}" | cat
    else
      ( sleep 1; echo select "${redisDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisHost}" "${redisPort}" | cat
    fi
  else
    echo "Cannot flush Redis because neither redis-cli nor telnet is available"
    exit 1
  fi
fi
