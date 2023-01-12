#!/bin/bash -e

scriptName="${0##*/}"
scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help  Show this message

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

source "${currentPath}/../core/prepare-parameters.sh"

"${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/image-cache-clean/web-server.sh"
