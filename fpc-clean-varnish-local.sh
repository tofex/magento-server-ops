#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Varnish host name, default: localhost
  -a  Varnish admin port, default: 6082
  -f  Varnish secret file, default: /etc/varnish/secret
  -o  List of hosts (optional)

Example: ${scriptName} -f
EOF
}

trim()
{
  echo -n "$1" | xargs
}

varnishHost="localhost"
varnishAdminPort="6082"
varnishSecretFile="/etc/varnish/secret"
hosts="-"

while getopts hv:a:f:o:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) varnishHost=$(trim "$OPTARG");;
    a) varnishAdminPort=$(trim "$OPTARG");;
    f) varnishSecretFile=$(trim "$OPTARG");;
    o) hosts=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -n "${varnishHost}" ]] && [[ -n "${varnishAdminPort}" ]]; then
  varnishadmAvailable=$(sudo which varnishadm | wc -l)
  if [[ "${varnishadmAvailable}" -eq 0 ]]; then
    echo "Cannot flush Varnish FPC cache because varnishadm is not available"
    exit 1
  fi
  if [[ -z "${hosts}" ]] || [[ "${hosts}" == "-" ]]; then
    echo "Flushing entire Varnish FPC"
    sudo varnishadm -T "${varnishHost}:${varnishAdminPort}" -S "${varnishSecretFile}" "ban req.url ~ /" >/dev/null
  else
    hostList=( $(echo "${hosts}" | tr "," "\n") )
    for host in "${hostList[@]}"; do
      echo "Flushing Varnish FPC for host name: ${host}"
      sudo varnishadm -T "${varnishHost}:${varnishAdminPort}" -S "${varnishSecretFile}" "ban req.http.host == ${host}" >/dev/null
    done
  fi
fi
