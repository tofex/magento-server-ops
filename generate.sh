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
  case ${option} in
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

if [[ -n "${memoryLimit}" ]]; then
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/generate-code.sh" -m "${memoryLimit}" -f
  else
    "${currentPath}/generate-code.sh" -m "${memoryLimit}"
  fi
else
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/generate-code.sh" -f
  else
    "${currentPath}/generate-code.sh"
  fi
fi

if [[ -n "${memoryLimit}" ]]; then
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/generate-static.sh" -m "${memoryLimit}" -f
  else
    "${currentPath}/generate-static.sh" -m "${memoryLimit}"
  fi
else
  if [[ "${force}" == 1 ]]; then
    "${currentPath}/generate-static.sh" -f
  else
    "${currentPath}/generate-static.sh"
  fi
fi
