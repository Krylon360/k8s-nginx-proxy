#!/bin/bash

# Encodes the environment variables into a Kubernetes secret.

EXPECTEDARGS=1
if [ $# -lt $EXPECTEDARGS ]; then
    echo "Usage: $0 <SERVICE_NAME>"
    echo "i.e.: $0 postgres"
    exit 0
fi

SERVICE_NAME=$1
sed -e "s#{{SERVICE_NAME}}#${SERVICE_NAME}#g" ./nginx-template.env > nginx.env

BASE64_ENC=$(cat nginx.env | base64 --wrap=0)
sed -e "s#{{config_data}}#${BASE64_ENC}#g" ./nginx-env-template.yaml > nginx-env.yaml
