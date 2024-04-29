#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --elasticsearchHost     Elasticsearch host name, default: 127.0.0.1
  --elasticsearchPort     Elasticsearch port, default: 9200
  --elasticsearchVersion  Elasticsearch version

Example: ${scriptName} --elasticsearchHost es --elasticsearchPort 9200 --elasticsearchVersion 7.9
EOF
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

elasticsearchHost=
elasticsearchPort=
elasticsearchVersion=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${elasticsearchHost}" ]]; then
  elasticsearchHost="127.0.0.1"
fi

if [[ -z "${elasticsearchPort}" ]]; then
  elasticsearchPort="9200"
fi

if [[ -z "${elasticsearchVersion}" ]]; then
  echo "No Elasticsearch version specified!"
  exit 1
fi

if [[ $(versionCompare "${elasticsearchVersion}" "7.0.0") == 0 ]] || [[ $(versionCompare "${elasticsearchVersion}" "7.0.0") == 2 ]]; then
  echo "Updating Elasticsearch settings for indexing"

  curl -XPUT -H "Content-Type: application/json" "http://${elasticsearchHost}:${elasticsearchPort}/_cluster/settings" -d '{ "transient": { "cluster.routing.allocation.disk.threshold_enabled": false } }'
  curl -XPUT -H "Content-Type: application/json" "http://${elasticsearchHost}:${elasticsearchPort}/_all/_settings" -d '{"index.blocks.read_only_allow_delete": null}'
else
  echo "No updating Elasticsearch settings for indexing"
fi
