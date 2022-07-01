#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --redisSessionHost      The host name of the Redis instance
  --redisSessionPort      The port of the Redis instance
  --redisSessionPassword  The password of the Redis instance (optional)
  --redisSessionDatabase  The number of the database to clean

Example: ${scriptName} --redisSessionHost localhost --redisSessionPort 6379 --redisSessionDatabase 0
EOF
}

redisSessionHost=
redisSessionPort=
redisSessionPassword=
redisSessionDatabase=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${redisSessionHost}" ]]; then
  echo "No Redis session host specified!"
  usage
  exit 1
fi

if [[ -z "${redisSessionPort}" ]]; then
  echo "No Redis session port specified!"
  usage
  exit 1
fi

if [[ -z "${redisSessionDatabase}" ]]; then
  echo "No Redis session database specified!"
  usage
  exit 1
fi

redisCliAvailable=$(which redis-cli | wc -l)
telnetAvailable=$(which telnet | wc -l)
if [[ "${redisCliAvailable}" -eq 1 ]]; then
  echo "Flushing Redis using redis-cli"
  if [[ -n "${redisSessionPassword}" ]] && [[ "${redisSessionPassword}" != "-" ]]; then
    REDISCLI_AUTH="${redisSessionPassword}" redis-cli -h "${redisSessionHost}" -p "${redisSessionPort}" -n "${redisSessionDatabase}" FLUSHDB
  else
    redis-cli -h "${redisSessionHost}" -p "${redisSessionPort}" -n "${redisSessionDatabase}" FLUSHDB
  fi
elif [[ "${telnetAvailable}" -eq 1 ]]; then
  echo "Flushing Redis using telnet"
  if [[ -n "${redisSessionPassword}" ]] && [[ "${redisSessionPassword}" != "-" ]]; then
    ( sleep 1; echo "auth ${redisSessionPassword}"; echo select "${redisSessionDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisSessionHost}" "${redisSessionPort}" | cat
  else
    ( sleep 1; echo select "${redisSessionDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisSessionHost}" "${redisSessionPort}" | cat
  fi
else
  echo "Cannot flush Redis because neither redis-cli nor telnet is available"
  exit 1
fi
