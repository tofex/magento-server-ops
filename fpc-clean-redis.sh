#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

redisFPC=$("${currentPath}/../core/server/redis/fpc/single.sh" | cat)

if [[ -n "${redisFPC}" ]]; then
  "${currentPath}/../core/script/redis/fpc/single.sh" "${currentPath}/cache-clean-redis/redis.sh"
fi
