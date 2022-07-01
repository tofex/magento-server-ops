#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

"${currentPath}/../core/script/magento/web-server.sh" "${currentPath}/modules-prepare/magento.sh" \
  -s "script:${currentPath}/modules-diff/web-server.sh:modules-diff.sh" \
  -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
  -a "script:${currentPath}/static-clean/web-server.sh:static-clean.sh"
