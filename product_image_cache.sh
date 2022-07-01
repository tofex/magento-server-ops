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
  -d  Number of days to check

Example: ${scriptName} -d 60
EOF
}

trim()
{
  echo -n "$1" | xargs
}

days=

while getopts hd:? option; do
  case ${option} in
    h) usage; exit 1;;
    d) days=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${days}" ]]; then
  echo "No days specified"
  usage;
  exit 1
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${type}" == "local" ]]; then
      echo "Checking on server: ${server}"
      cd "${webPath}"

      if [[ ${magentoVersion:0:1} == "1" ]]; then
        mediaPath="media"
      else
        mediaPath="pub/media"
      fi

      directoryList=( $(find "${mediaPath}/catalog/product/cache/" -mindepth 3 -maxdepth 4 -type d | grep -v "/images$" | grep -v "/placeholder$" | grep -v "/[0-9a-z_]$" | sort -nr) )

      collectedCacheDirectories=( )

      for directory in "${directoryList[@]}"; do
        echo "Checking directory: ${directory}"
        add=1
        for collectedCacheDirectory in "${collectedCacheDirectories[@]}"; do
          if [[ "${collectedCacheDirectory}" =~ "${directory}" ]]; then
            add=0
          fi
        done
        if [[ "${add}" == 1 ]]; then
          collectedCacheDirectories+=( "${directory}" )
        fi
      done

      cacheDirectories=( $( echo "${collectedCacheDirectories[@]}" | tr ' ' '\n' | sort -n | uniq | tr '\n' ' ' ) )

      for cacheDirectory in "${cacheDirectories[@]}"; do
        echo -n "Checking: ${cacheDirectory}"
        inUse=$(find "${cacheDirectory}/" -type f -ctime -"${days}" | head -n1 | wc -l)
        echo -en "\r\e[K"
        if [[ "${inUse}" == 0 ]]; then
          echo "${cacheDirectory}: $(du -hs "${cacheDirectory}" | awk '{print $1;}')"
        fi
      done
    fi
  fi
done
