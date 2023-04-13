#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Magento version
  -w  Web path of Magento installation
  -q  Quiet (optional)

Example: ${scriptName} -m 2.3.7 -w /var/www/magento/htdocs
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
webPath=
quiet=0

while getopts hm:e:d:r:c:n:w:u:g:t:v:p:z:x:y:q? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) magentoVersion=$(trim "$OPTARG");;
    e) ;;
    d) ;;
    r) ;;
    c) ;;
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
    q) quiet=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No magento version specified!"
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  exit 1
fi

if [[ ! -d "${webPath}" ]]; then
  echo "No web path available!"
  exit 1
fi

if [[ ${magentoVersion:0:1} == "2" ]]; then
  if [[ "${quiet}" == 0 ]]; then
    echo "Determining required frontend locales"
  fi

  cd "${webPath}"
  # shellcheck disable=SC2016
  php -r 'foreach (["app/etc/config.php", "app/etc/config.settings.php"] as $configFile) {if (file_exists($configFile)) {$config = include $configFile;if (is_array($config) && array_key_exists("system", $config)) {foreach ($config["system"] as $scope) {if (is_array($scope) && array_key_exists("general", $scope)) {$section = $scope["general"];if (is_array($section) && array_key_exists("locale", $section)) {$group = $section["locale"];if (is_array($group) && array_key_exists("code", $group)) {$field = $group["code"];echo "$field\n";}}}}}}}'
fi
