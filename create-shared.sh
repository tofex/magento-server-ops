#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -f  File to move
  -o  Overwrite existing files (Optional)
  -s  Shared file path, default: shared
  -r  revert moving file to shared
  -n  No update of link in server deployment

Example: ${scriptName} -f media -o
EOF
}

trim()
{
  echo -n "$1" | xargs
}

fileName=
overwrite=0
sharedPath=
revert=0
updateLink=1

while getopts hf:os:rn? option; do
  case "${option}" in
    h) usage; exit 1;;
    f) fileName=$(trim "$OPTARG");;
    o) overwrite=1;;
    s) sharedPath=$(trim "$OPTARG");;
    r) revert=1;;
    n) updateLink=0;;
    ?) usage; exit 1;;
  esac
done

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi
currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${fileName}" ]]; then
  echo "No file specified"
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="static"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ "${revert}" == 1 ]]; then
  "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/create-shared/web-server.sh" \
    -s "${sharedPath}" \
    -f "${fileName}" \
    -r
else
  if [[ "${overwrite}" == 1 ]]; then
    "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/create-shared/web-server.sh" \
      -s "${sharedPath}" \
      -f "${fileName}" \
      -o
  else
    "${currentPath}/../core/script/web-server/all.sh" "${currentPath}/create-shared/web-server.sh" \
      -s "${sharedPath}" \
      -f "${fileName}"
  fi
fi

if [[ "${revert}" == 0 ]]; then
  if [[ "${updateLink}" == 1 ]]; then
    "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/create-shared/env-web-server.sh" \
      -f "${fileName}" \
      -s "${sharedPath}"
  fi
else
  if [[ "${updateLink}" == 1 ]]; then
    "${currentPath}/../core/script/env/web-servers.sh" "${currentPath}/create-shared/env-web-server.sh" \
      -f "${fileName}" \
      -s "${sharedPath}" \
      -r
  fi
fi
