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
aspenMeshHelmChartRepo="https://aspenmesh.github.io/aspenmesh-charts/"
helmAddErr=$(helm repo add aspenmesh ${aspenMeshHelmChartRepo} 2>&1 >/dev/null || true)
helmUpdateErr=$(helm repo update 2>&1 >/dev/null || true)
if [[ -n "${helmAddErr}" || -n "${helmUpdateErr}" ]]; then
  echo ""
  echo "***Failed to add Aspen Mesh Chart helm repository ${aspenMeshHelmChartRepo}***"
  echo "Please send the following error messages to hello@aspenmesh.io:"
  echo "${helmAddErr}"
  echo "${helmUpdateErr}"
  echo ""
  exit 1
fi

helmInstallErr=$(helm upgrade --install aspenmesh-collector aspenmesh/aspenmesh-collector -n aspenmesh --create-namespace --set apiKey=${apiKey} --set endpoint=${endpoint} 2>&1 >/dev/null || true)

if [[ -n "${helmInstallErr}" ]]; then
  echo ""
  echo "***Failed to install Aspen Mesh Collector by helm***"
  echo "Please send the following error messages to hello@aspenmesh.io:"
  echo "${helmInstallErr}"
  echo ""
  exit 1
fi

echo ""
echo "***Aspen Mesh Collector has been installed successfully!***"
echo "All the Aspen Mesh Collector pods can be found by command 'kubectl get pods -n aspenmesh'"
echo ""

