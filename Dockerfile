FROM crazymax/alpine-s6:latest

# Internal settings
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=60000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=1

# These ENV variables are required to be set

# Either API_KEY_FILE or API_KEY must be set, the file has higher priority
ENV API_KEY=""
ENV API_KEY_FILE=""
# Either ZONE_FILE or ZONE muat be set, the file has higher priority
ENV ZONE=""
ENV ZONE_FILE=""

# These ENV variables are optional

ENV CF_API="https://api.cloudflare.com/client/v4"
ENV CRON="*/5 * * * *"
ENV CUSTOM_LOOKUP_CMD=""
ENV DELETE_ON_STOP=""
ENV DNS_SERVER="1.1.1.1"
ENV INTERFACE=""
ENV IP_TYPE="4"
ENV PROXIED=""
ENV RRTYPE="A"
# Either SUBDOMAIN_FILE or SUBDOMAIN can be set, the file has higher priority
ENV SUBDOMAIN="@"
ENV SUBDOMAIN_FILE=""
ENV WEBHOOK_URL=""

COPY root /

RUN apk add --no-cache jq curl bind-tools && \
    chmod -R -f +x /etc/cont-init.d /etc/cont-finish.d /etc/services.d/crond /app/cloudflare.sh && \
    mkdir -p /config

ENTRYPOINT [ "/init" ]
