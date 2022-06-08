#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name
  -e  Environment property file
  -w  Web path
  -f  File to move
  -s  Shared file path
  -r  Revert moving file to shared

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
envPropertyFile=
webPath=
fileName=
sharedPath=
revert=0

while getopts hn:e:w:u:g:t:v:p:z:x:y:f:s:r? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    e) envPropertyFile=$(trim "$OPTARG");;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    f) fileName=$(trim "$OPTARG");;
    s) sharedPath=$(trim "$OPTARG");;
    r) revert=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  usage
  exit 1
fi

if [[ -z "${envPropertyFile}" ]]; then
  echo "No environment property file specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

if [[ -z "${fileName}" ]]; then
  echo "No file name specified!"
  usage
  exit 1
fi

if [[ -z "${sharedPath}" ]]; then
  echo "No shared path specified!"
  usage
  exit 1
fi

webRoot=$(dirname "${webPath}")

if [[ "${revert}" == 0 ]]; then
  addLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
  echo "Adding link: ${addLink} to deployment"
  ini-set "${envPropertyFile}" "no" "${serverName}" "link" "${addLink}"
else
  removeLink="${webRoot}/${sharedPath}/${fileName}:${fileName}"
  echo "Removing link: ${removeLink} from deployment"
  ini-del "${envPropertyFile}" "${serverName}" "link" "${removeLink}"
fi
