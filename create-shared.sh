#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -f  file to move
  -o  Overwrite existing files (Optional)
  -s  shared file path, default: shared
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
sharedPath="static"
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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
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
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    webRoot=$(dirname "${webPath}")

    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

      echo "--- Creating shared file on local server: ${server} ---"
      if [[ "${revert}" == 1 ]]; then
        "${currentPath}/create-shared-local.sh" \
          -w "${webPath}" \
          -u "${webUser}" \
          -g "${webGroup}" \
          -s "${webRoot}/${sharedPath}" \
          -f "${fileName}" \
          -r
      else
        if [[ "${overwrite}" == 1 ]]; then
          "${currentPath}/create-shared-local.sh" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -s "${webRoot}/${sharedPath}" \
            -f "${fileName}" \
            -o
        else
          "${currentPath}/create-shared-local.sh" \
            -w "${webPath}" \
            -u "${webUser}" \
            -g "${webGroup}" \
            -s "${webRoot}/${sharedPath}" \
            -f "${fileName}"
        fi
      fi
    else
      echo "--- Todo: Creating shared file on remote server: ${server} ---"
      exit 1
    fi

    if [[ "${revert}" == 0 ]]; then
      if [[ "${updateLink}" == 1 ]]; then
        addLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
        echo "Adding link: ${addLink} to deployment"
        ini-set "${currentPath}/../env.properties" "no" "${server}" "link" "${addLink}"
      fi
    else
      if [[ "${updateLink}" == 1 ]]; then
        removeLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
        echo "Removing link: ${removeLink} from deployment"
        ini-del "${currentPath}/../env.properties" "${server}" "link" "${removeLink}"
      fi
    fi
  fi
done
