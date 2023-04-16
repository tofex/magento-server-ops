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
  -i  Memory limit (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

phpExecutable=
memoryLimit=

while getopts hb:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) phpExecutable=$(trim "$OPTARG");;
    i) memoryLimit=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

"${currentPath}/../core/script/run.sh" "install,database" "${currentPath}/reindex-all/database.sh"

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/reindex-all/web-server.sh" \
      --phpExecutable "${phpExecutable}" \
      --memoryLimit "${memoryLimit}"
  else
    "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/reindex-all/web-server.sh" \
      --phpExecutable "${phpExecutable}"
  fi
else
  if [[ -n "${memoryLimit}" ]]; then
    "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/reindex-all/web-server.sh" \
      --memoryLimit "${memoryLimit}"
  else
    "${currentPath}/../core/script/run.sh" "install,webServer" "${currentPath}/reindex-all/web-server.sh"
  fi
fi
