FROM crazymax/alpine-s6:latest

RUN apk add --no-cache jq curl bind-tools

COPY root /

RUN chmod +x /etc/cont-init.d -R -f
RUN chmod +x /etc/cont-finish.d -R -f
RUN chmod +x /etc/services.d/crond -R -f
RUN chmod +x /app/cloudflare.sh

# In the /config path will be placed the cloudflare.conf, generated in the cf setup
RUN mkdir -p /config

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME 60000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 1

ENTRYPOINT /init