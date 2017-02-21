FROM haproxy:1.7.2-alpine

MAINTAINER Christian Schnidrig

RUN /bin/ln -s -f /etc/haproxy/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

RUN set -x \
    \
    && apk add --no-cache --virtual .build-deps \
        vim \
        lua5.3-lualdap \
        luarocks5.3 \
        lua5.3-sec \
        lua5.3-dev \
        gcc \
        build-base

RUN /usr/bin/luarocks-5.3 install lbase64 \
    && /usr/bin/luarocks-5.3 install redis-lua


