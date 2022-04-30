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
  case "${option}" in
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

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ -n "${database}" ]]; then
    upgrade=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "upgrade")
    if [[ "${upgrade}" == 1 ]] || [[ "${upgrade}" == "yes" ]]; then
      port=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "port")
      user=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "user")
      password=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "password")
      name=$(ini-parse "${currentPath}/../env.properties" "yes" "${database}" "name")
      if [[ -z "${port}" ]]; then
        echo "No database port specified!"
        exit 1
      fi
      if [[ -z "${user}" ]]; then
        echo "No database user specified!"
        exit 1
      fi
      if [[ -z "${password}" ]]; then
        echo "No database password specified!"
        exit 1
      fi
      if [[ -z "${name}" ]]; then
        echo "No database name specified!"
        exit 1
      fi

      type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      if [[ "${type}" == "local" ]]; then
        echo "--- Upgrade database on local server: ${server} ---"
        webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
        webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
        webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

        if [[ -n "${memoryLimit}" ]]; then
          if [[ "${force}" == 1 ]]; then
            "${currentPath}/database-upgrade-local.sh" \
              -v "${magentoVersion}" \
              -w "${webPath}" \
              -u "${webUser}" \
              -g "${webGroup}" \
              -o "localhost" \
              -p "${port}" \
              -r "${user}" \
              -s "${password}" \
              -n "${name}" \
              -m "${memoryLimit}" \
              -f
          else
            "${currentPath}/database-upgrade-local.sh" \
              -v "${magentoVersion}" \
              -w "${webPath}" \
              -u "${webUser}" \
              -g "${webGroup}" \
              -o "localhost" \
              -p "${port}" \
              -r "${user}" \
              -s "${password}" \
              -n "${name}" \
              -m "${memoryLimit}"
          fi
        else
          if [[ "${force}" == 1 ]]; then
            "${currentPath}/database-upgrade-local.sh" \
              -v "${magentoVersion}" \
              -w "${webPath}" \
              -u "${webUser}" \
              -g "${webGroup}" \
              -o "localhost" \
              -p "${port}" \
              -r "${user}" \
              -s "${password}" \
              -n "${name}" \
              -f
          else
            "${currentPath}/database-upgrade-local.sh" \
              -v "${magentoVersion}" \
              -w "${webPath}" \
              -u "${webUser}" \
              -g "${webGroup}" \
              -o "localhost" \
              -p "${port}" \
              -r "${user}" \
              -s "${password}" \
              -n "${name}"
          fi
        fi
      fi
    fi
  fi
done
