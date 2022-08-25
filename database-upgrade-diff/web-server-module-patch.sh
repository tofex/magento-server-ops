#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -w  Web path of Magento installation
  -b  PHP executable (optional)
  -q  Quiet mode, list only patches

Example: ${scriptName} -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webPath=
phpExecutable=
quiet=0

while getopts hn:w:u:g:t:v:p:z:x:y:b:q? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    w) webPath=$(trim "$OPTARG");;
    u) ;;
    g) ;;
    t) ;;
    v) ;;
    p) ;;
    z) ;;
    x) ;;
    y) ;;
    b) phpExecutable=$(trim "$OPTARG");;
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

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
  echo "${sourcePatchClasses[@]}"
fi
