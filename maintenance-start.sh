#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

"${currentPath}/../core/script/run.sh" "webServer:single" "${currentPath}/maintenance-start/web-server.sh"
