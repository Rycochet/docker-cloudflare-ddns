#FROM ghcr.io/two70/s6-alpine
FROM oznu/s6-alpine:3.12-${S6_ARCH:-aarch64}

ENV YOUR_BOT_TOKEN=${YOUR_BOT_TOKEN}
ENV RECIPIENT_CHAT_ID=${RECIPIENT_CHAT_ID}

RUN apk add --no-cache jq curl bind-tools

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 CF_API=https://api.cloudflare.com/client/v4 RRTYPE=A CRON="*/5	*	*	*	*"

COPY root /
