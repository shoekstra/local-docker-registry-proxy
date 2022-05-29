# local-docker-registry-proxy

Proxies Docker registries:

- quay.io
- docker.io
- gcr.io

All you need is to `mkcert "*.local"` and place the certificate files in [the proper place](services/traefik/certs) according to the filenames dictated by [config.toml](services/traefik/traefik/dynamic/config.toml). This is handled by running `make create-certs`

![Screenshot](screenshot.png)

## Usage

`make` targets:

```sh
check-deps                     Checks all required dependencies are installed
create-certs                   Create required certificate
start                          Start local docker registries
stop                           Stop local docker registries
```

Run `make start` to start the local registries. It will also take care of creating the certificates and copying them to the required location:

## k3d

```sh
k3d cluster create \
    --servers 1 \
    --agents 1 \
    --k3s-server-arg='--no-deploy=traefik' \
    --volume "${HOME}/dev/local-docker-registry-proxy/registries.yaml:/etc/rancher/k3s/registries.yaml" \
    --volume "${HOME}/.local/share/mkcert/rootCA.pem:/etc/ssl/certs/Registry_Root_CA.pem" \
    --wait \
    --network k3d-backend
```

## kind

Each node needs an `extraMounts` block:

```yaml
    extraMounts:
      - containerPath: /registry-ssl-certs
        hostPath: local-registry/services/traefik/certs
```

And a `containerdConfigPatches` block:

```yaml
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://registry-dockerio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-dockerio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"

    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
      endpoint = ["https://registry-gcrio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-gcrio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"

    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
      endpoint = ["https://registry-quayio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-quayio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"
```

Example `kind-config.yaml` file:

```yaml
---
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: tpe-demo
nodes:
  - role: control-plane
    extraMounts:
      - containerPath: /registry-ssl-certs
        hostPath: local-registry/services/traefik/certs
  - role: worker
    extraMounts:
      - containerPath: /registry-ssl-certs
        hostPath: local-registry/services/traefik/certs
  - role: worker
    extraMounts:
      - containerPath: /registry-ssl-certs
        hostPath: local-registry/services/traefik/certs
  - role: worker
    extraMounts:
      - containerPath: /registry-ssl-certs
        hostPath: local-registry/services/traefik/certs
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://registry-dockerio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-dockerio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"

    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
      endpoint = ["https://registry-gcrio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-gcrio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"

    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
      endpoint = ["https://registry-quayio.local"]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-quayio.local".tls]
      ca_file = "/registry-ssl-certs/rootCA.pem"
```

Create your kind cluster:

```sh
kind create cluster --config=kind-config.yaml
```

If you get the error `ERROR: Network "kind" needs to be recreated - option "com.docker.network.driver.mtu" has changed`, delete the `kind` network using `docker network rm kind` and try again.

## Links

- http://localhost:3000 - Grafana
- http://localhost:5000 - Local Docker Registry
- http://localhost:8080 - Traefik
- http://localhost:8000/registry-local/metrics - Prometheus metrics endpoint of `registry-local` instance.
- http://localhost:8000/registry-quayio/metrics - Prometheus metrics endpoint of `registry-quayio` instance.
- http://localhost:8000/registry-dockerio/metrics - Prometheus metrics endpoint of `registry-dockerio` instance.
- http://localhost:8000/registry-gcrio/metrics - Prometheus metrics endpoint of `registry-dockerio` instance.
- http://localhost:9090 - Prometheus
