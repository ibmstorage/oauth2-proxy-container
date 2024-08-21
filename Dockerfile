ARG RUNTIME_IMAGE=registry.redhat.io/ubi9/ubi-micro:latest
FROM openshift/golang-builder:rhel_8_golang_1.22 AS builder
COPY ${REMOTE_SOURCE} ${REMOTE_SOURCE_DIR}
WORKDIR $REMOTE_SOURCE_DIR/app

# Fetch dependencies
RUN go mod vendor
RUN go mod download

# Arguments go here so that the previous steps can be cached if no external
# sources have changed.

# Original Dockerfile has `ARG VERSION` instead. Here we rename it to `OAUTH2_PROXY_VERSION`
# as the golang_builder base image already defines an environment variable `VERSION` which means
# any call later to `$VERSION` actually refers to the latter.
ARG OAUTH2_PROXY_VERSION=v7.6.0
RUN VERSION=${OAUTH2_PROXY_VERSION} make build && touch jwt_signing_key.pem

FROM ${RUNTIME_IMAGE}
COPY --from=builder ${REMOTE_SOURCE_DIR}/app/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder ${REMOTE_SOURCE_DIR}/app/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

ENTRYPOINT ["/bin/oauth2-proxy"]

# Build specific labels
LABEL maintainer="Guillaume Abrioux <gabrioux@ibm.com>"
LABEL com.redhat.component="oauth2-proxy-container"
LABEL version=v7.6.0
LABEL name="oauth2-proxy"
LABEL description="IBM Ceph Storage oauth2-proxy container"
LABEL summary="oauth2-proxy container on RHEL 9 for IBM Ceph Storage"
LABEL io.k8s.display-name="oauth2-proxy on RHEL 9"
LABEL io.openshift.tags="ibm ceph oauth2-proxy"
