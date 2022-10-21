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
  -q  Quiet mode, list only changes

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

quiet=0

while getopts hq? option; do
  case "${option}" in
    h) usage; exit 1;;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ "${quiet}" == 0 ]]; then
  echo "Determining inactive modules in source"
fi
inactiveModuleNames=( $("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-upgrade-diff/web-server-module-inactive.sh" --quiet) )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#inactiveModuleNames[@]} inactive modules"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module versions in source"
fi
sourceCodeModules=( $("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-upgrade-diff/web-server-module-source.sh" --quiet) )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#sourceCodeModules[@]} modules"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining active modules in source"
fi
for inactiveModuleName in "${inactiveModuleNames[@]}"; do
  for i in "${!sourceCodeModules[@]}"; do
    if [[ "${sourceCodeModules[i]}" =~ ^${inactiveModuleName}: ]]; then
      unset 'sourceCodeModules[i]'
    fi
  done
done
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#sourceCodeModules[@]} active modules"
fi
( IFS=$'\n'; echo "${sourceCodeModules[*]}" ) > /tmp/module_code.list

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module versions in database"
fi
databaseModules=( $("${currentPath}/../core/script/run-quiet.sh" "database:single" "${currentPath}/database-upgrade-diff/database-module-setup.sh" --quiet) )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#databaseModules[@]} modules"
fi
( IFS=$'\n'; echo "${databaseModules[*]}" ) > /tmp/module_deployed.list

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module changes"
fi
if [[ $(grep -vxcFf /tmp/module_deployed.list /tmp/module_code.list) -gt 0 ]]; then
  moduleChanges=( $(grep -vxFf /tmp/module_deployed.list /tmp/module_code.list) )
else
  moduleChanges=()
fi
if [[ "${quiet}" == 0 ]] || [[ "${#moduleChanges[@]}" -gt 0 ]]; then
  if [[ "${#moduleChanges[@]}" -gt 0 ]]; then
    echo "Found ${#moduleChanges[@]} module change(s):"
    ( IFS=$'\n'; echo "${moduleChanges[*]}" )
  else
    echo "Found no module changes"
  fi
fi

magentoVersion=$("${currentPath}/../core/server/magento/version.sh")

if [[ $(versionCompare "${magentoVersion}" "2.3.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.3.0") == 2 ]]; then
  if [[ "${quiet}" == 0 ]]; then
    echo "Determining patches in source"
  fi
  sourcePatchClasses=( $("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-upgrade-diff/web-server-module-patch.sh" --quiet) )
  if [[ "${quiet}" == 0 ]]; then
    echo "Found ${#sourcePatchClasses[@]} patches"
  fi
  if [[ "${quiet}" == 0 ]]; then
    echo "Determining active patches in source"
  fi
  inactiveModuleNamespaces=()
  for inactiveModuleName in "${inactiveModuleNames[@]}"; do
    inactiveModuleNamespace=$(echo "${inactiveModuleName}/" | sed 's/_/\//g')
    inactiveModuleNamespaces+=("${inactiveModuleNamespace}")
  done
  sourcePatchNamespaces=()
  for sourcePatchClass in "${sourcePatchClasses[@]}"; do
    sourcePatchNamespace=$(echo "${sourcePatchClass}" | sed 's/\\/\//g')
    sourcePatchNamespaces+=("${sourcePatchNamespace}")
  done
  for inactiveModuleNamespace in "${inactiveModuleNamespaces[@]}"; do
    for i in "${!sourcePatchClasses[@]}"; do
      if [[ "${sourcePatchNamespaces[i]}" =~ ^${inactiveModuleNamespace} ]]; then
        unset 'sourcePatchClasses[i]'
      fi
    done
  done
  if [[ "${quiet}" == 0 ]]; then
    echo "Found ${#sourcePatchClasses[@]} active patches"
  fi
  ( IFS=$'\n'; echo "${sourcePatchClasses[*]}" ) > /tmp/patch_code.list

  if [[ "${quiet}" == 0 ]]; then
    echo "Determining patches in database"
  fi
  databasePatchClasses=( $("${currentPath}/../core/script/run-quiet.sh" "database:single" "${currentPath}/database-upgrade-diff/database-module-patch.sh" --quiet) )
  if [[ "${quiet}" == 0 ]]; then
    echo "Found ${#databasePatchClasses[@]} patches"
  fi
  ( IFS=$'\n'; echo "${databasePatchClasses[*]}" ) > /tmp/patch_deployed.list
  sed -i -e 's/\\\\/\\/g' /tmp/patch_deployed.list

  if [[ "${quiet}" == 0 ]]; then
    echo "Determining patch changes"
  fi
  if [[ $(grep -vxcFf /tmp/patch_deployed.list /tmp/patch_code.list) -gt 0 ]]; then
    patchChanges=( $(grep -vxFf /tmp/patch_deployed.list /tmp/patch_code.list) )
  else
    patchChanges=()
  fi
  if [[ "${quiet}" == 0 ]] || [[ "${#patchChanges[@]}" -gt 0 ]]; then
    if [[ "${#patchChanges[@]}" -gt 0 ]]; then
      echo "Found ${#patchChanges[@]} patch change(s):"
      ( IFS=$'\n'; echo "${patchChanges[*]}" )
    else
      echo "Found no patch changes"
    fi
  fi
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining database schema changes"
fi
currentDatabaseSchemaHash=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-upgrade-diff/web-server-database-schema-hash.sh" --quiet)
if [[ "${quiet}" == 0 ]]; then
  echo "Current database schema hash:"
  echo "${currentDatabaseSchemaHash}"
fi
sourceDatabaseSchemaHash=$("${currentPath}/../core/script/run-quiet.sh" "webServer:single" "${currentPath}/database-schema-hash/web-server.sh" --quiet)
if [[ "${quiet}" == 0 ]]; then
  echo "Source database schema hash:"
  echo "${sourceDatabaseSchemaHash}"
fi
if [[ "${currentDatabaseSchemaHash}" != "${sourceDatabaseSchemaHash}" ]]; then
  echo "Found database schema changes"
else
  if [[ "${quiet}" == 0 ]]; then
    echo "Found no database schema changes"
  fi
fi
