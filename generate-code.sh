#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Memory limit (optional)
  -f  Force (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

memoryLimit=
force=0

while getopts hm:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

      echo "--- Generating code on local server: ${server} ---"
      if [[ -n "${memoryLimit}" ]]; then
        if [[ "${force}" == 1 ]]; then
          "${currentPath}/generate-code-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -m "${memoryLimit}" \
            -f
        else
          "${currentPath}/generate-code-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -m "${memoryLimit}"
        fi
      else
        if [[ "${force}" == 1 ]]; then
          "${currentPath}/generate-code-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -f
        else
          "${currentPath}/generate-code-local.sh" \
            -v "${magentoVersion}" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}"
        fi
      fi
    fi
  fi
done
