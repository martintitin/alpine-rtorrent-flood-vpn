FROM alpine:latest

LABEL maintainer="martintitin"

ENV UID=991
ENV GID=991
ENV RTORRENT_LISTEN_PORT=49314
ENV RTORRENT_DHT_PORT=49313
ENV DNS_SERVER_IP='8.8.8.8'

RUN addgroup -g ${GID} rtorrent \
  && adduser -h /home/rtorrent -s /bin/sh -G rtorrent -D -u ${UID} rtorrent \
  && runtime_pkgs="supervisor git openrc iptables shadow su-exec nginx ca-certificates php php-fpm php-json openvpn curl python3 nodejs npm ffmpeg sox unzip mktorrent xmlrpc-c libtorrent rtorrent" \
  && apk -U upgrade \
  && apk add --no-cache ${runtime_pkgs}

# cleanup
RUN rm -rf /var/cache/apk/* /tmp/* \
&& rm -rf /usr/local/include /usr/local/share

# Copy startup shells
COPY sh/* /usr/local/bin/

# Copy configuration files

# Set-up php-fpm
COPY config/php-fpm81_www.conf /etc/php81/php-fpm.d/www.conf 

# Set-up nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure supervisor
RUN sed -i -e "s/loglevel=info/loglevel=error/g" /etc/supervisord.conf
COPY config/rtorrentvpn_supervisord.conf /etc/supervisor.d/rtorrentvpn.ini

# Set-up rTorrent
COPY config/rtorrent.rc /home/rtorrent/rtorrent.rc

# Set-up permissions
RUN mkdir -p /var/lib/nginx \
  && chown -R rtorrent:rtorrent /home/rtorrent /var/lib/nginx  \
  && npm install --global flood

VOLUME /data /config

# WebUI
EXPOSE 8080

CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
