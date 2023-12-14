FROM alpine:3.19

ARG TIMONI_VERSION=0.17.0

RUN apk update && apk add --no-cache \
    bash \
    curl \
    docker-credential-ecr-login

RUN curl -Lo /tmp/timoni.tar.gz "https://github.com/stefanprodan/timoni/releases/download/v${TIMONI_VERSION}/timoni_${TIMONI_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/timoni.tar.gz -C /usr/local/bin && \
    rm /tmp/timoni.tar.gz

RUN delgroup ping && \
    addgroup -g 998 ping && \
    adduser -D -u 999 argocd
USER argocd

RUN mkdir -p /home/argocd/.docker
RUN mkdir -p /home/argocd/cmp-server/config
COPY docker.json /home/argocd/.docker/config.json
COPY plugin.yml /home/argocd/cmp-server/config/plugin.yaml
COPY init.sh /home/argocd/init.sh

ENTRYPOINT [ "/var/run/argocd/argocd-cmp-server" ]