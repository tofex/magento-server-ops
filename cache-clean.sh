#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${currentPath}/cache-clean-files.sh"
"${currentPath}/cache-clean-redis.sh"
