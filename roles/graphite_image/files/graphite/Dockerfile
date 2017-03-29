FROM ubuntu:16.04

MAINTAINER Christian Schnidrig

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       graphite-web \
       graphite-carbon \
       apache2 \
       libapache2-mod-wsgi \
       sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY apache2_graphite.conf /etc/apache2/sites-available/graphite.conf
RUN a2enmod wsgi \
            headers \
    && a2dissite 000-default.conf \
    && a2ensite graphite.conf

COPY local_settings.py /etc/graphite/local_settings.py
COPY default_graphite-carbon /etc/default/graphite-carbon
COPY carbon.conf /etc/carbon/carbon.conf
COPY storage-schemas.conf /etc/carbon/storage-schemas.conf
COPY storage-aggregation.conf /etc/carbon/storage-aggregation.conf

COPY run.sh /run.sh

ENV TERM=xterm

EXPOSE 80 2003 2004 2013 2014

#VOLUME /var/lib/graphite/
#VOLUME /var/lib/graphite/log

ENTRYPOINT [ "/run.sh" ]
