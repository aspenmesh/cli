#!/usr/bin/env bash

set -Eeuo pipefail

if ! [ -x "$(command -v helm)" ]; then
  echo "Missing dependency: Helm" >&2
  echo "This script requires Helm to install the Aspen Mesh distribution for OpenTelemetry. Please visit https://helm.sh/docs/intro/install/ and rerun this script once Helm is installed." >&2
  exit 1
fi

usage() {
  echo "
usage: ${0} [flags] [-h|--help]
Flags               Purpose
--api-key           Required; The API key provided upon initial signup to Aspen Mesh
" >&2

    exit 1
}

endpoint="${AM_METRICS_ENDPOINT:-https://metrics.cloud.aspenmesh.io/write}"
apiKey=""
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --api-key)
    apiKey="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    usage
    ;;
  esac
done

if [[ -z "${apiKey}" ]]; then
  echo "missing <api-key> argument" >&2
  usage
fi

# Add the Aspen Mesh Helm Repository
helm repo add aspenmesh https://aspenmesh.github.io/aspenmesh-charts/
helm repo update

isHelmInstallSuccessful="true"
helm upgrade --install aspenmesh-collector aspenmesh/aspenmesh-collector -n aspenmesh --create-namespace --set apiKey=${apiKey} --set endpoint=${endpoint} || isHelmInstallSuccessful="false"

if [[ "${isHelmInstallSuccessful}" == "false" ]]; then
  echo "
***Failed to install Aspen Mesh Helm Charts***
If you're stuck, reach out to us at hello@aspenmesh.io and include the error message above.
"
fi

