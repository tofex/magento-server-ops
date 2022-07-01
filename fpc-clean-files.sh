#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

webServer=$("${currentPath}/../core/server/web-server/single.sh" | cat)

if [[ -n "${webServer}" ]]; then
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/fpc-clean-files/web-server.sh"
fi
