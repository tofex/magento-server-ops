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

if [[ $(which id 2>/dev/null | wc -l) -gt 0 ]]; then
  currentGroup=$(id -g -n)
else
  currentGroup=$(grep -qe "^${currentUser}:" /etc/passwd && grep -e ":$(grep -e "^${currentUser}:" /etc/passwd | awk -F: '{print $4}'):" /etc/group | awk -F: '{print $1}' || echo "")
fi
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${fileName}" ]]; then
  echo "No file specified"
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  sharedPath="shared"
fi

fileStatus=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/create-shared/web-server-check.sh" \
  --fileName "${fileName}")

if [[ "${fileStatus}" == "mounted" ]]; then
  echo "${fileName} is mounted"
else
  if [[ "${revert}" == 1 ]]; then
    "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/create-shared/web-server.sh" \
      --sharedPath "${sharedPath}" \
      --fileName "${fileName}" \
      --revert
  else
    if [[ "${overwrite}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/create-shared/web-server.sh" \
        --sharedPath "${sharedPath}" \
        --fileName "${fileName}" \
        --overwrite
    else
      "${currentPath}/../core/script/run.sh" "webServer:all" "${currentPath}/create-shared/web-server.sh" \
        --sharedPath "${sharedPath}" \
        --fileName "${fileName}"
    fi
  fi

  if [[ "${revert}" == 0 ]]; then
    if [[ "${updateLink}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/create-shared/web-server-env.sh" \
        --sharedPath "${sharedPath}" \
        --fileName "${fileName}"
    fi
  else
    if [[ "${updateLink}" == 1 ]]; then
      "${currentPath}/../core/script/run.sh" "webServer:all,env:local" "${currentPath}/create-shared/web-server-env.sh" \
        --sharedPath "${sharedPath}" \
        --fileName "${fileName}" \
        --revert
    fi
  fi
fi
