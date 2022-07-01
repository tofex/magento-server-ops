#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

"${currentPath}/session-clean-files.sh"
"${currentPath}/session-clean-database.sh"
"${currentPath}/session-clean-redis.sh"
