#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -o  Host name
  -t  Varnish host name, default: localhost
  -d  Varnish admin port, default: 6082
  -w  Varnish secret file, default: /etc/varnish/secret

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
host=

while getopts hn:o:a:e:c:l:k:r:f:i:b:s:t:p:d:w:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) ;;
    o) host=$(trim "$OPTARG");;
    a) ;;
    e) ;;
    c) ;;
    l) ;;
    k) ;;
    r) ;;
    f) ;;
    i) ;;
    b) ;;
    s) ;;
    t) varnishHost=$(trim "$OPTARG");;
    p) ;;
    d) varnishAdminPort=$(trim "$OPTARG");;
    w) varnishSecretFile=$(trim "$OPTARG");;
    v) ;;
    ?) usage; exit 1;;
  esac
done

if [[ -n "${varnishHost}" ]] && [[ -n "${varnishAdminPort}" ]]; then
  varnishadmAvailable=$(sudo which varnishadm | wc -l)
  if [[ "${varnishadmAvailable}" -eq 0 ]]; then
    echo "Cannot flush Varnish FPC cache because varnishadm is not available"
    exit 1
  fi
  echo "Flushing Varnish FPC for host name: ${host}"
  varnishadm -T "${varnishHost}:${varnishAdminPort}" -S "${varnishSecretFile}" "ban req.http.host == ${host}" >/dev/null
fi
