#!/bin/bash -e

scriptPath="${BASH_SOURCE[0]}"

if [[ -L "${scriptPath}" ]]; then
  scriptPath=$(realpath "${scriptPath}")
fi

currentPath="$( cd "$( dirname "${scriptPath}" )" && pwd )"

varnish=$("${currentPath}/../core/server/varnish/single.sh" | cat)

if [[ -n "${varnish}" ]]; then
  "${currentPath}/../core/script/host/varnish.sh" "${currentPath}/fpc-clean-varnish/varnish.sh"
fi
