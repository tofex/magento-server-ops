#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                Show this message
  --redisCacheHost      The host name of the Redis instance
  --redisCachePort      The port of the Redis instance
  --redisCachePassword  The password of the Redis instance (optional)
  --redisCacheDatabase  The number of the database to clean

Example: ${scriptName} --redisCacheHost localhost --redisCachePort 6379 --redisCacheDatabase 0
EOF
}

redisCacheHost=
redisCachePort=
redisCachePassword=
redisCacheDatabase=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${redisCacheHost}" ]]; then
  echo "No Redis cache host specified!"
  usage
  exit 1
fi

if [[ -z "${redisCachePort}" ]]; then
  echo "No Redis cache port specified!"
  usage
  exit 1
fi

if [[ -z "${redisCacheDatabase}" ]]; then
  echo "No Redis cache database specified!"
  usage
  exit 1
fi

if [[ -n "${redisCacheHost}" ]] && [[ -n "${redisCachePort}" ]] && [[ -n "${redisCacheDatabase}" ]]; then
  redisCliAvailable=$(which redis-cli | wc -l)
  telnetAvailable=$(which telnet | wc -l)
  if [[ "${redisCliAvailable}" -eq 1 ]]; then
    echo "Flushing Redis using redis-cli"
    if [[ -n "${redisCachePassword}" ]] && [[ "${redisCachePassword}" != "-" ]]; then
      REDISCLI_AUTH="${redisCachePassword}" redis-cli -h "${redisCacheHost}" -p "${redisCachePort}" -n "${redisCacheDatabase}" FLUSHDB
    else
      redis-cli -h "${redisCacheHost}" -p "${redisCachePort}" -n "${redisCacheDatabase}" FLUSHDB
    fi
  elif [[ "${telnetAvailable}" -eq 1 ]]; then
    echo "Flushing Redis using telnet"
    if [[ -n "${redisCachePassword}" ]] && [[ "${redisCachePassword}" != "-" ]]; then
      ( sleep 1; echo "auth ${redisCachePassword}"; echo select "${redisCacheDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisCacheHost}" "${redisCachePort}" | cat
    else
      ( sleep 1; echo select "${redisCacheDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisCacheHost}" "${redisCachePort}" | cat
    fi
  else
    echo "Cannot flush Redis because neither redis-cli nor telnet is available"
    exit 1
  fi
fi
