ARG RUNTIME_IMAGE=registry.redhat.io/ubi9/ubi-micro@sha256:2173487b3b72b1a7b11edc908e9bbf1726f9df46a4f78fd6d19a2bab0a701f38
FROM registry.redhat.io/rhel8/go-toolset:1.21 AS builder

USER root

WORKDIR $GOPATH/src/github.com/oauth2-proxy/oauth2-proxy

COPY go.mod go.sum ./
RUN go mod download

COPY oauth2-proxy/* /app/
WORKDIR /app/

ARG OAUTH2_PROXY_VERSION=v7.6.0
RUN VERSION=${OAUTH2_PROXY_VERSION} make build && touch jwt_signing_key.pem

FROM ${RUNTIME_IMAGE}
COPY --from=builder /src/github.com/oauth2-proxy/oauth2-proxy/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder /src/github.com/oauth2-proxy/oauth2-proxy/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

ENTRYPOINT ["/bin/oauth2-proxy"]

# Build specific labels
LABEL maintainer="Guillaume Abrioux <gabrioux@ibm.com>"
LABEL com.redhat.component="oauth2-proxy-container"
LABEL version=v7.6.0
LABEL name=rhceph/oauth2-proxy-rhel9
LABEL description="IBM Ceph Storage oauth2-proxy container"
LABEL summary="oauth2-proxy container on RHEL 9 for IBM Ceph Storage"
LABEL io.k8s.display-name="oauth2-proxy on RHEL 9"
LABEL io.openshift.tags="ibm ceph oauth2-proxy"
