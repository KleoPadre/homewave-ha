FROM mikebrady/shairport-sync:4.3.7

RUN apk add --no-cache bash gettext jq

COPY --chmod=755 start-addon.sh /run.sh
COPY shairport-sync.conf.tpl /etc/homewave/shairport-sync.conf.tpl
COPY --chmod=755 rootfs/etc/cont-init.d/10-audio-check.sh /etc/cont-init.d/10-audio-check.sh

ENV TEMPLATE_PATH=/etc/homewave/shairport-sync.conf.tpl

ENTRYPOINT ["/run.sh"]
