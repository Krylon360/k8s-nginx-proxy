#!/bin/bash

# Encodes the environment variables into a Kubernetes secret.

EXPECTEDARGS=5
if [ $# -lt $EXPECTEDARGS ]; then
  echo "Usage: $0 <K8S_SERVICE_NAME> <K8S_NAMESPACE> <K8S_DOMAIN> <K8S_DNS_HOST> <NGINX_PORT>"
    echo "i.e.: $0 frontend default kube.local 10.1.0.10 80"
    exit 0
fi

K8S_SERVICE_NAME=$1
K8S_NAMESPACE=$2
K8S_DOMAIN=$3
K8S_DNS_HOST=$4
NGINX_PORT=$5

K8S_SERVICE_FQDN=${K8S_SERVICE_NAME}.${K8S_NAMESPACE}.svc.${K8S_DOMAIN}

sed -e "s#{{K8S_SERVICE_NAME}}#${K8S_SERVICE_NAME}#g" ./nginx-template.env > nginx.env
sed -i "s#{{K8S_SERVICE_FQDN}}#${K8S_SERVICE_FQDN}#g" nginx.env
sed -i "s#{{K8S_DNS_HOST}}#${K8S_DNS_HOST}#g" nginx.env
sed -i "s#{{NGINX_PORT}}#${NGINX_PORT}#g" nginx.env

BASE64_ENC=$(cat nginx.env | base64 --wrap=0)
sed -e "s#{{config_data}}#${BASE64_ENC}#g" ./nginx-env-template.yaml > nginx-env.yaml
