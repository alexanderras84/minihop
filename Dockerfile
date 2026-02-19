FROM alpine:3.20
ARG TARGETPLATFORM

ENV ALLOWED_CLIENTS=127.0.0.1
ENV ALLOWED_CLIENTS_FILE=

ENV DYNDNS_CRON_SCHEDULE="*/1 * * * *"

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD (pgrep "nginx" > /dev/null) || exit 1

# Expose Ports
EXPOSE 80/tcp
EXPOSE 443/tcp

RUN echo "I'm building for $TARGETPLATFORM"

# Update Base
RUN apk update && apk upgrade

# Create Users
RUN addgroup minihop && adduser -D -H -G minihop minihop

# Install needed packages and clean up
RUN apk add --no-cache jq tini curl bash gnupg procps ca-certificates openssl dog lua5.4-filesystem ipcalc libcap nginx nginx-mod-stream supercronic step-cli bind-tools && \
    rm -f /etc/nginx/conf.d/*.conf && \
    rm -rf /var/cache/apk/*

# Setup Folder(s)
RUN mkdir -p /etc/minihop/

# Copy Files
COPY nginx.conf /etc/nginx/nginx.conf
COPY routing.map /etc/nginx/routing.map
COPY entrypoint.sh /entrypoint.sh
COPY generateACL.sh /generateACL.sh
COPY dynDNSCron.sh /dynDNSCron.sh

RUN chown -R minihop:minihop /etc/nginx/ && \
    chown -R minihop:minihop /etc/minihop/ && \
    chown -R minihop:minihop /var/log/nginx/ && \
    chown -R minihop:minihop /var/lib/nginx/ && \
    chown -R minihop:minihop /run/nginx/ && \
    chmod +x /entrypoint.sh && \
    chmod +x /generateACL.sh && \
    chmod +x dynDNSCron.sh

USER minihop

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]
