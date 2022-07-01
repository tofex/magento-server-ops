#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --redisFPCHost      The host name of the Redis instance
  --redisFPCPort      The port of the Redis instance
  --redisFPCPassword  The password of the Redis instance (optional)
  --redisFPCDatabase  The number of the database to clean

Example: ${scriptName} --redisFPCHost localhost --redisFPCPort 6379 --redisFPCDatabase 0
EOF
}

redisFPCHost=
redisFPCPort=
redisFPCPassword=
redisFPCDatabase=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${redisFPCHost}" ]]; then
  echo "No Redis FPC host specified!"
  usage
  exit 1
fi

if [[ -z "${redisFPCPort}" ]]; then
  echo "No Redis FPC port specified!"
  usage
  exit 1
fi

if [[ -z "${redisFPCDatabase}" ]]; then
  echo "No Redis FPC database specified!"
  usage
  exit 1
fi

redisCliAvailable=$(which redis-cli | wc -l)
telnetAvailable=$(which telnet | wc -l)
if [[ "${redisCliAvailable}" -eq 1 ]]; then
  echo "Flushing Redis using redis-cli"
  if [[ -n "${redisFPCPassword}" ]] && [[ "${redisFPCPassword}" != "-" ]]; then
    REDISCLI_AUTH="${redisFPCPassword}" redis-cli -h "${redisFPCHost}" -p "${redisFPCPort}" -n "${redisFPCDatabase}" FLUSHDB
  else
    redis-cli -h "${redisFPCHost}" -p "${redisFPCPort}" -n "${redisFPCDatabase}" FLUSHDB
  fi
elif [[ "${telnetAvailable}" -eq 1 ]]; then
  echo "Flushing Redis using telnet"
  if [[ -n "${redisFPCPassword}" ]] && [[ "${redisFPCPassword}" != "-" ]]; then
    ( sleep 1; echo "auth ${redisFPCPassword}"; echo select "${redisFPCDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisFPCHost}" "${redisFPCPort}" | cat
  else
    ( sleep 1; echo select "${redisFPCDatabase}"; sleep 1; echo flushdb; sleep 1; ) | telnet "${redisFPCHost}" "${redisFPCPort}" | cat
  fi
else
  echo "Cannot flush Redis because neither redis-cli nor telnet is available"
  exit 1
fi
