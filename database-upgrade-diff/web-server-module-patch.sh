#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help           Show this message
  --webPath        Web path of Magento installation
  --phpExecutable  PHP executable (optional)
  --quiet          Quiet mode, list only patches

Example: ${scriptName} --webPath /var/www/magento/htdocs
EOF
}

webPath=
phpExecutable=
quiet=0

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "Invalid web path specified!"
  exit 1
fi

if [[ -z "${phpExecutable}" ]]; then
  phpExecutable="php"
fi

cd "${webPath}"

if [[ "${quiet}" == 0 ]]; then
  echo "Determining patches in path: ${webPath}"
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

if [[ "${#sourcePatchClasses[@]}" -gt 0 ]]; then
  if [[ "${quiet}" == 1 ]]; then
    echo "${sourcePatchClasses[@]}"
  else
    printf "%s\n" "${sourcePatchClasses[@]}"
  fi
fi
