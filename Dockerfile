#FROM ghcr.io/two70/s6-alpine
#FROM oznu/s6-alpine:3.12-${S6_ARCH:-aarch64}
FROM alpine:3.18
ARG S6_OVERLAY_VERSION=3.1.5.0

ENV YOUR_BOT_TOKEN=${YOUR_BOT_TOKEN}
ENV RECIPIENT_CHAT_ID=${RECIPIENT_CHAT_ID}

RUN apk add --no-cache jq curl bind-tools

RUN chmod +x /etc/cont-init.d -R -f
RUN chmod +x /etc/cont-finish.d -R -f
RUN chmod +x /etc/services.d/crond -R -f
RUN chmod +x /app/cloudflare.sh

RUN mkdir -p /config

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpvf /tmp/s6-overlay-x86_64.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpvf /tmp/s6-overlay-symlinks-noarch.tar.xz

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 CF_API=https://api.cloudflare.com/client/v4 RRTYPE=A CRON="*/5	*	*	*	*"

COPY root /

ENTRYPOINT /init