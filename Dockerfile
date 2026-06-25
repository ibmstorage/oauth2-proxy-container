ARG RUNTIME_IMAGE=registry.redhat.io/ubi10/ubi-minimal:latest
FROM registry.redhat.io/rhel8/go-toolset:1.25 AS builder

WORKDIR $GOPATH/src/github.com/oauth2-proxy/oauth2-proxy

# Fetch dependencies
COPY oauth2-proxy/go.mod oauth2-proxy/go.sum ./
RUN go mod download

COPY oauth2-proxy/. ./

# Arguments go here so that the previous steps can be cached if no external
# sources have changed.

# Original Dockerfile has `ARG VERSION` instead. Here we rename it to `OAUTH2_PROXY_VERSION`
# as the golang_builder base image already defines an environment variable `VERSION` which means
# any call later to `$VERSION` actually refers to the latter.
ARG OAUTH2_PROXY_VERSION=v7.14.0
RUN VERSION=${OAUTH2_PROXY_VERSION} make build && touch jwt_signing_key.pem

FROM ${RUNTIME_IMAGE}
COPY --from=builder /src/github.com/oauth2-proxy/oauth2-proxy/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder /src/github.com/oauth2-proxy/oauth2-proxy/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

ENTRYPOINT ["/bin/oauth2-proxy"]

# Build specific labels
LABEL maintainer="Guillaume Abrioux <gabrioux@ibm.com>"
LABEL com.redhat.component="oauth2-proxy-container"
LABEL version=v7.14.0
LABEL name=rhceph/oauth2-proxy-rhel10
LABEL description="IBM Ceph Storage oauth2-proxy container"
LABEL summary="oauth2-proxy container on RHEL 9 for IBM Ceph Storage"
LABEL io.k8s.display-name="oauth2-proxy on RHEL 10"
LABEL io.openshift.tags="ibm ceph oauth2-proxy"
LABEL cpe=cpe:/a:redhat:ceph_storage:9.1::el10

# Z-stream indicator
LABEL Z-VERSION="9.1"
