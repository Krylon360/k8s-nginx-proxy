## What is k8s-nginx-proxy?
k8s-nginx-proxy is an "applicance" to use Nginx as a reverse-proxy on Kubernetes in the way it was meant to be consumed: via DNS.

k8s-nginx-proxy creates a [Kubernetes](https://github.com/kubernetes/kubernetes) configuration template for a [Secret](http://kubernetes.io/v1.0/docs/user-guide/secrets.html) based on environmental variables. This Secret holds the necessary input needed to create an Nginx configuration that uses the [DNS resolver module](http://nginx.org/en/docs/http/ngx_http_core_module.html#resolver) to work with K8s' [SkyDNS add-on](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns) and enable a reverse-proxy to throw in front of Kubernetes Services that auto-updates the servers it's proxying to based on Kuberentes DNS entries; thus, creating a reverse-proxy for your K8s Services that dynamically updates itself.

## Why would you want to use this?
For starters, K8s [Services](https://github.com/kubernetes/kubernetes/blob/master/docs/user-guide/services.md) are simple load-balancers - they provide a single choke point / abstraction to 1+ pods, and thats about it. Services are really only consumable internally in a Kubernetes cluster, so they do not natively provide solutions for capabilties such as reverse-proxying, SSL-termination, caching etc - features that become very relevant if you adopt the container model for your stack and take notice of the ephemeral-ness of Pods in the K8s, especially when Pods start inter-depending on one another for functionality.

k8s-nginx-proxy is modeled after and is a mix of both [GoogleCloudPlatform/nginx-ssl-proxy](https://github.com/GoogleCloudPlatform/nginx-ssl-proxy)
and [New Relic's Monitoring Agent](https://github.com/kubernetes/kubernetes/tree/master/examples/newrelic).

It 
This repository is used to build a Docker image that acts as an HTTP [reverse proxy](http://en.wikipedia.org/wiki/Reverse_proxy) with optional (but strongly encouraged) support for acting as an [SSL termination proxy](http://en.wikipedia.org/wiki/SSL_termination_proxy). The proxy can also be configured to enforce [HTTP basic access authentication](http://en.wikipedia.org/wiki/Basic_access_authentication). Nginx is the HTTP server, and its SSL configuration is included (and may be modified to suit your needs) at `nginx/proxy_ssl.conf` in this repository.

## Building the Image
Build the image yourself by cloning this repository then running:

```shell
docker build -t nginx-ssl-proxy .
```

## Using with Kubernetes
This image is optimized for use in a Kubernetes cluster to provide SSL termination for other services in the cluster. It should be deployed as a [Kubernetes replication controller](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/replication-controller.md) with a [service and public load balancer](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/services.md) in front of it. SSL certificates, keys, and other secrets are managed via the [Kubernetes Secrets API](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/docs/design/secrets.md).

Here's how the replication controller and service would function terminating SSL for Jenkins in a Kubernetes cluster:

![](img/architecture.png)

See [https://github.com/GoogleCloudPlatform/kube-jenkins-imager](https://github.com/GoogleCloudPlatform/kube-jenkins-imager) for a complete tutorial that uses the `nginx-ssl-proxy` in Kubernetes.

## Run an SSL Termination Proxy from the CLI
To run an SSL termination proxy you must have an existing SSL certificate and key. These instructions assume they are stored at /path/to/secrets/ and named `cert.crt` and `key.pem`. You'll need to change those values based on your actual file path and names.

1. **Create a DHE Param**

    The nginx SSL configuration for this image also requires that you generate your own DHE parameter. It's easy and takes just a few minutes to complete:

    ```shell
    openssl dhparam -out /path/to/secrets/dhparam.pem 2048
    ```

2. **Launch a Container**

    Modify the below command to include the actual address or host name you want to proxy to, as well as the correct /path/to/secrets for your certificate, key, and dhparam:

    ```shell
    docker run \
      -e ENABLE_SSL=true \
      -e TARGET_SERVICE=THE_ADDRESS_OR_HOST_YOU_ARE_PROXYING_TO \
      -v /path/to/secrets/cert.crt:/etc/secrets/proxycert \
      -v /path/to/secrets/key.pem:/etc/secrets/proxykey \
      -v /path/to/secrets/dhparam.pem:/etc/secrets/dhparam \
      nginx-ssl-proxy
    ```
    The really important thing here is that you map in your cert to `/etc/secrets/proxycert`, your key to `/etc/secrets/proxykey`, and your dhparam to `/etc/secrets/dhparam` as shown in the command above. 

3. **Enable Basic Access Authentication**

    Create an htpaddwd file:

    ```shell
    htpasswd -nb YOUR_USERNAME SUPER_SECRET_PASSWORD > /path/to/secrets/htpasswd
    ```

    Launch the container, enabling the feature and mapping in the htpasswd file:

    ```shell
    docker run \
      -e ENABLE_SSL=true \
      -e ENABLE_BASIC_AUTH=true \
      -e TARGET_SERVICE=THE_ADDRESS_OR_HOST_YOU_ARE_PROXYING_TO \
      -v /path/to/secrets/cert.crt:/etc/secrets/proxycert \
      -v /path/to/secrets/key.pem:/etc/secrets/proxykey \
      -v /path/to/secrets/dhparam.pem:/etc/secrets/dhparam \
      -v /path/to/secrets/htpasswd:/etc/secrets/htpasswd \
      nginx-ssl-proxy
    ```
