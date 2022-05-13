#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path of Magento installation
  -o  Database hostname, default: localhost
  -p  Port of the database, default: 3306
  -r  Database user
  -s  Database password
  -n  Database name
  -q  Quiet mode, list only changes
  -e  PHP executable (optional)

Example: ${scriptName} -w /var/www/magento/htdocs -o localhost -p 3306 -r username -s secret -n projectdb
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

webPath=
databaseHost="localhost"
databasePort="3306"
databaseUser=
databasePassword=
databaseName=
magentoVersion=
quiet=0
phpExecutable="php"

while getopts hw:o:p:r:s:n:v:qe:? option; do
  case ${option} in
    h) usage; exit 1;;
    w) webPath=$(trim "$OPTARG");;
    o) databaseHost=$(trim "$OPTARG");;
    p) databasePort=$(trim "$OPTARG");;
    r) databaseUser=$(trim "$OPTARG");;
    s) databasePassword=$(trim "$OPTARG");;
    v) magentoVersion=$(trim "$OPTARG");;
    n) databaseName=$(trim "$OPTARG");;
    q) quiet=1;;
    e) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  currentPath="$(dirname "$(readlink -f "$0")")"
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

if [[ -z "${databaseHost}" ]]; then
  echo "No database host specified!"
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  echo "No database port specified!"
  exit 1
fi

if [[ -z "${databaseUser}" ]]; then
  echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  echo "No database name specified!"
  exit 1
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining inactive modules"
fi
inactiveModuleNames=( $(bash -c "${phpExecutable} -r \"\\\$config=include 'app/etc/config.php'; foreach (array_keys(\\\$config['modules']) as \\\$moduleName) {if (\\\$config['modules'][\\\$moduleName] == 0) {echo \\\"\\\$moduleName\n\\\";}}\" | sort -n") )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#inactiveModuleNames[@]} inactive modules"
fi

if [[ "${quiet}" == 0 ]]; then
  echo "Determining module versions in source code in path: ${webPath}"
fi
sourceCodeModuleFiles=( $(find . -name module.xml -not -path "./vendor/amzn/amazon-payments-magento-2-plugin/src/*" -not -path "./vendor/mirasvit/module-report-api/src/*" -exec grep -l "setup_version\s*=" {} \;) )
sourceCodeModules=()
for sourceCodeModuleFile in "${sourceCodeModuleFiles[@]}"; do
  sourceCodeModule=$(cat "${sourceCodeModuleFile}" | tr '\n' ' ' | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*setup_version\s*=\s*\"([p0-9\.\-]*)\".*/\1:\2/' | grep -v "^Magento_TestSetup" | cat)
  sourceCodeModule=$(trim "${sourceCodeModule}")
  if [[ -n "${sourceCodeModule}" ]]; then
    sourceCodeModules+=("${sourceCodeModule}")
  fi
done
IFS=$'\n' sourceCodeModules=($(sort <<<"${sourceCodeModules[*]}"))
unset IFS
#sourceCodeModules=( $(find . -name module.xml -not -path "./vendor/amzn/amazon-payments-magento-2-plugin/src/*" -not -path "./vendor/mirasvit/module-report-api/src/*" -exec grep "setup_version\s=" {} \; | sed -E 's/.*name\s*=\s*\"([a-zA-Z0-9_]*)\".*setup_version\s*=\s*\"([p0-9\.\-]*)\".*/\1:\2/' | grep -v "^Magento_TestSetup" | sort) )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#sourceCodeModules[@]} modules"
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
export MYSQL_PWD="${databasePassword}"
databaseModules=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT CONCAT(module, \":\", schema_version) FROM setup_module ORDER BY module ASC;") )
if [[ "${quiet}" == 0 ]]; then
  echo "Found ${#databaseModules[@]} modules"
fi
( IFS=$'\n'; echo "${databaseModules[*]}" ) > /tmp/module_deployed.list

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

if [[ $(versionCompare "${magentoVersion}" "2.3.0") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "2.3.0") == 2 ]]; then
  if [[ "${quiet}" == 0 ]]; then
    echo "Determining patches in source code in path: ${webPath}"
  fi
  patchFiles=( $(grep -r -l -E "\bSchemaPatchInterface\b|\bDataPatchInterface\b|\bPatchInterface\b" app/ vendor/ | grep -E "\.php$" | sort) )
  sourcePatchClasses=()
  for patchFile in "${patchFiles[@]}"; do
    if [[ $(grep -c "apply" "${patchFile}") -gt 0 ]]; then
      abstractClass=$(grep -oE "abstract\s*class" "${patchFile}" | cat)
      if [[ -n "${abstractClass}" ]]; then
        continue
      fi
      nameSpace=$(grep -oE "^namespace\s*([a-zA-Z0-9_]+\\\\*)*" "${patchFile}" | cut -d " " -f 2)
      if [[ -n "${nameSpace}" ]]; then
        className=$(basename "${patchFile}" ".php")
        patchClass="${nameSpace}\\${className}"
        sourcePatchClasses+=("${patchClass}")
      fi;
    fi;
  done
  sourcePatchClasses=( $( IFS=$'\n'; echo "${sourcePatchClasses[*]}" | grep -vE "^Magento\\\\Framework\\\\Setup\\\\" | grep -vE "^Magento\\\\TestSetupDeclarationModule[0-9]+\\\\Setup\\\\" | grep -vE "^Magento\\\\InventoryShipping\\\\Setup\\\\Patch\\\\InitializeDefaultSourceForShipments$" | sort -Vf ) )
  if [[ "${quiet}" == 0 ]]; then
    echo "Found ${#sourcePatchClasses[@]} patches"
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
  export MYSQL_PWD="${databasePassword}"
  databasePatchClasses=( $(mysql -h"${databaseHost}" -P"${databasePort}" -u"${databaseUser}" "${databaseName}" -s -N -e "SELECT DISTINCT(patch_name) FROM patch_list ORDER BY patch_name ASC;") )
  if [[ "${quiet}" == 0 ]]; then
    echo "Found ${#databasePatchClasses[@]} patches"
  fi
  ( IFS=$'\n'; echo "${databasePatchClasses[*]}" ) > /tmp/patch_deployed.list
  sed -i -e 's/\\\\/\\/g' /tmp/patch_deployed.list

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
