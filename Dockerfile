FROM alpine@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b

ARG TIMONI_VERSION=0.17.0

RUN apk update && apk add --no-cache \
    bash=5.2.21-r0 \
    curl=8.5.0-r0 \
    docker-credential-ecr-login=0.6.0-r17

RUN curl -Lo /tmp/timoni.tar.gz "https://github.com/stefanprodan/timoni/releases/download/v${TIMONI_VERSION}/timoni_${TIMONI_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/timoni.tar.gz -C /usr/local/bin && \
    rm /tmp/timoni.tar.gz

RUN delgroup ping && \
    addgroup -g 998 ping && \
    adduser -D -u 999 argocd
USER argocd

RUN mkdir -p /home/argocd/cmp-server/config
COPY plugin.yml /home/argocd/cmp-server/config/plugin.yaml
COPY init.sh /home/argocd/init.sh

ENTRYPOINT [ "/var/run/argocd/argocd-cmp-server" ]