#!/bin/bash

# Encodes the environment variables into a Kubernetes secret.

EXPECTEDARGS=3
if [ $# -lt $EXPECTEDARGS ]; then
    echo "Usage: $0 <K8S_SERVICE_NAME> <K8S_DNS_HOST> <NGINX_PORT>"
    echo "i.e.: $0 postgres 10.1.0.10 80"
    exit 0
fi

K8S_SERVICE_NAME=$1
sed -e "s#{{K8S_SERVICE_NAME}}#${K8S_SERVICE_NAME}#g" ./nginx-template.env > nginx.env

K8S_DNS_HOST=$2
sed -e "s#{{K8S_DNS_HOST}}#${K8S_DNS_HOST}#g" ./nginx.env >> nginx.env

NGINX_PORT=$3
sed -e "s#{{NGINX_PORT}}#${NGINX_PORT}#g" ./nginx.env >> nginx.env

BASE64_ENC=$(cat nginx.env | base64 --wrap=0)
sed -e "s#{{config_data}}#${BASE64_ENC}#g" ./nginx-env-template.yaml > nginx-env.yaml
