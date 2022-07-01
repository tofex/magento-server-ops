#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

"${currentPath}/fpc-clean-files.sh"
"${currentPath}/fpc-clean-redis.sh"
"${currentPath}/fpc-clean-varnish.sh"
