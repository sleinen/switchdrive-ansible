FROM alpine:3.5

MAINTAINER Christian Schnidrig

RUN apk --update add python py-setuptools py-pip && \
    pip install elasticsearch-curator=={{curator_version}} && \
    apk del py-pip && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["/usr/bin/curator"]
