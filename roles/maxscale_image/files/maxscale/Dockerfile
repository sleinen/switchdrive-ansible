FROM centos:7
MAINTAINER Andrea Sosso <andrea@sosso.me>
MAINTAINER Christian Schnidrig

ENV MAXSCALE_VERSION 1.4.3

RUN rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB \
    && yum -y install https://downloads.mariadb.com/enterprise/yzsw-dthq/generate/10.0/mariadb-enterprise-repository.rpm \
    && yum -y update \
    && yum -y install maxscale-$MAXSCALE_VERSION \
    && yum clean all \
    && rm -rf /tmp/*

RUN cp /etc/maxscale.cnf.template /etc/maxscale.cnf

COPY start /

# EXPOSE the MaxScale default ports

## RW Split Listener
EXPOSE 4006

## Read Connection Listener
EXPOSE 4008

## Debug Listener
EXPOSE 4442

## CLI Listener
EXPOSE 6603

# Running MaxScale
ENTRYPOINT ["/start"]

