#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help           Show this message
  --webPath        Web path of Magento installation
  --phpExecutable  PHP executable (optional)
  --quiet          Quiet mode, list only changes

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
phpExecutable=
quiet=0

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module versions in path: ${webPath}"
fi

sourceCodeModuleFiles=( $(find . -name module.xml -not -path "./vendor/magento/magento2-base/dev/*" -not -path "./dev/tests/setup-integration/*" -not -path "./vendor/amzn/amazon-payments-magento-2-plugin/src/*" -not -path "./vendor/mirasvit/module-report-api/src/*" -not -path "./vendor/magento/composer-root-update-plugin/*" -not -path "./var/vendor/magento/composer-root-update-plugin/etc/*" -exec grep -l "setup_version\s*=" {} \;) )

sourceCodeModules=()
for sourceCodeModuleFile in "${sourceCodeModuleFiles[@]}"; do
  sourceCodeModule=$(cat "${sourceCodeModuleFile}" | tr '\n' ' ' | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*setup_version\s*=\s*\"([p0-9\.\-]*)\".*/\1:\2/' | grep -v "^Magento_A:" | grep -v "^Magento_B:" | grep -v "^Magento_TestModule" | grep -v "^Magento_TestSetup" | cat)
  sourceCodeModule=$(trim "${sourceCodeModule}")
  if [[ -n "${sourceCodeModule}" ]]; then
    sourceCodeModules+=("${sourceCodeModule}")
  fi
done
IFS=$'\n' sourceCodeModules=($(sort <<<"${sourceCodeModules[*]}"))
unset IFS

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#sourceCodeModules[@]} modules"
fi

if [[ "${#sourceCodeModules[@]}" -gt 0 ]]; then
  if [[ "${quiet}" == 1 ]]; then
    echo "${sourceCodeModules[@]}"
  else
    printf "%s\n" "${sourceCodeModules[@]}"
  fi
fi
