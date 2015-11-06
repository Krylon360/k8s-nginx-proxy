#!/bin/bash
# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
source /etc/nginx-env/config

echo "here0"
# Env says we're using SSL 
if [ -n "${ENABLE_SSL+1}" ] && [ "${ENABLE_SSL,,}" = "true" ]; then
  echo "here0a"
  echo "Enabling SSL..."
  cp /usr/src/proxy_ssl.conf /etc/nginx/conf.d/proxy.conf
else
  # No SSL
  echo "here0b"
  echo "Enabling *Without* SSL..."
  cp /usr/src/proxy_nossl.conf /etc/nginx/conf.d/proxy.conf
fi

## If an htpasswd file is provided, download and configure nginx 
#if [ -n "${ENABLE_BASIC_AUTH+1}" ] && [ "${ENABLE_BASIC_AUTH,,}" = "true" ]; then
#  echo "Enabling basic auth..."
#   sed -i "s/#auth_basic/auth_basic/g;" /etc/nginx/conf.d/proxy.conf
#fi

# If the SERVICE_HOST_ENV_NAME and SERVICE_PORT_ENV_NAME vars are provided,
# they point to the env vars set by Kubernetes that contain the actual
# target address and port. Override the default with them.
#if [ -n "${SERVICE_HOST_ENV_NAME+1}" ]; then
#  TARGET_SERVICE=${!SERVICE_HOST_ENV_NAME}
#fi
#if [ -n "${SERVICE_PORT_ENV_NAME+1}" ]; then
#  TARGET_SERVICE="$TARGET_SERVICE:${!SERVICE_PORT_ENV_NAME}"
#fi

show_val() { echo "${!1}"; }

echo "here1"

K8S_SERVICE_NAME_CAP=`echo $K8S_SERVICE_NAME | awk '{print toupper($0)}'`
echo "here2 - $K8S_SERVICE_NAME_CAP"
SERVICE_PORT="$K8S_SERVICE_NAME_CAP"_SERVICE_PORT
echo "here3 - $SERVICE_PORT"
TARGET_SERVICE="$K8S_SERVICE_NAME":"$(show_val $SERVICE_PORT)"
echo "Target service: $TARGET_SERVICE"

echo "here4"
# Tell nginx the address and port of the service to proxy to
sed -i "s/{{TARGET_SERVICE}}/${TARGET_SERVICE}/g;" /etc/nginx/conf.d/proxy.conf
sed -i "s/{{K8S_DNS_HOST}}/${K8S_DNS_HOST}/g;" /etc/nginx/conf.d/proxy.conf
sed -i "s/{{NGINX_PORT}}/${NGINX_PORT}/g;" /etc/nginx/conf.d/proxy.conf

echo "here5"


cat /etc/nginx-env/config
echo "---------------------"
cat /etc/nginx/conf.d/proxy.conf


echo "Starting nginx..."
nginx -g 'daemon off;'
