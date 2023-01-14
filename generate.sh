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
  -h  Show this message
  -b  PHP executable (optional)
  -m  Memory limit (optional)
  -f  Force (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

phpExecutable=
memoryLimit=
force=0

while getopts hb:m:f? option; do
  case ${option} in
    h) usage; exit 1;;
    b) phpExecutable=$(trim "$OPTARG");;
    m) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/generate-code.sh" -b "${phpExecutable}" -m "${memoryLimit}" -f
    else
      "${currentPath}/generate-code.sh" -b "${phpExecutable}" -m "${memoryLimit}"
    fi
  else
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/generate-code.sh" -b "${phpExecutable}" -f
    else
      "${currentPath}/generate-code.sh" -b "${phpExecutable}"
    fi
  fi
else
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
fi

if [[ -n "${phpExecutable}" ]]; then
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
else
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
fi
