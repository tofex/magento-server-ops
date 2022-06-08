#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path of Magento installation
  -e  PHP executable (optional)
  -q  Quiet mode, list only changes

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

while getopts hn:w:u:g:t:v:p:z:x:y:c:q? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    c) phpExecutable=$(trim "$OPTARG");;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

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

sourceCodeModuleFiles=( $(find . -name module.xml -not -path "./vendor/amzn/amazon-payments-magento-2-plugin/src/*" -not -path "./vendor/mirasvit/module-report-api/src/*" -exec grep -l "setup_version\s*=" {} \;) )

sourceCodeModules=()
for sourceCodeModuleFile in "${sourceCodeModuleFiles[@]}"; do
  sourceCodeModule=$(cat "${sourceCodeModuleFile}" | tr '\n' ' ' | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*setup_version\s*=\s*\"([p0-9\.\-]*)\".*/\1:\2/' | grep -v "^Magento_TestSetup" | cat)
  sourceCodeModule=$(trim "${sourceCodeModule}")
  if [[ -n "${sourceCodeModule}" ]]; then
    sourceCodeModules+=("${sourceCodeModule}")
  fi
done
IFS=$'\n' sourceCodeModules=($(sort <<<"${sourceCodeModules[*]}"))
unset IFS

#sourceCodeModules=( $(find . -name module.xml -not -path "./vendor/amzn/amazon-payments-magento-2-plugin/src/*" -not -path "./vendor/mirasvit/module-report-api/src/*" -exec grep "setup_version\s=" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*setup_version\s*=\s*\"([p0-9\.\-]*)\".*/\1:\2/' | grep -v "^Magento_TestSetup" | sort) )

if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#sourceCodeModules[@]} modules"
fi

if [[ "${#sourceCodeModules[@]}" -gt 0 ]]; then
  echo "${sourceCodeModules[@]}"
fi
