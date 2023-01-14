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

while getopts hb:i:f? option; do
  case "${option}" in
    h) usage; exit 1;;
    b) phpExecutable=$(trim "$OPTARG");;
    i) memoryLimit=$(trim "$OPTARG");;
    f) force=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -n "${phpExecutable}" ]]; then
  if [[ -n "${memoryLimit}" ]]; then
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --memoryLimit "${memoryLimit}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --memoryLimit "${memoryLimit}"
    fi
  else
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --phpExecutable "${phpExecutable}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --phpExecutable "${phpExecutable}"
    fi
  fi
else
  if [[ -n "${memoryLimit}" ]]; then
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --memoryLimit "${memoryLimit}" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --memoryLimit "${memoryLimit}"
    fi
  else
    if [[ "${force}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh" \
        --force
    else
      "${currentPath}/../core/script/run.sh" "install,webServer:single" "${currentPath}/generate-code/install-web-server.sh" \
        --generatedHashScript "script:${currentPath}/generated-hash/web-server.sh:generated-hash.sh" \
        --generatedCleanScript "script:${currentPath}/generated-clean/web-server.sh:generated-clean.sh"
    fi
  fi
fi
