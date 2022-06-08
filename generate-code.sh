#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Memory limit (optional)
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

while getopts hi:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -n "${memoryLimit}" ]]; then
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-code/magento.sh" \
      -a "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
      -i "${memoryLimit}" \
      -f
  else
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-code/magento.sh" \
      -a "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
      -i "${memoryLimit}"
  fi
else
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-code/magento.sh" \
      -a "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
      -f
  else
    "${currentPath}/../core/script/magento/web-servers.sh" "${currentPath}/generate-code/magento.sh" \
      -a "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
      -l "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh"
  fi
fi
