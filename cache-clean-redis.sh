#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "redisCache:ignore" "${currentPath}/cache-clean-redis/redis.sh"
