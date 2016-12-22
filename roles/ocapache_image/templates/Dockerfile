FROM ubuntu:16.04

MAINTAINER Christian Schnidrig

# add multiverse repo (for mod_fastcgi)
RUN apt-get update && apt-get install -y \
        software-properties-common \
    && apt-add-repository multiverse \
    && rm -rf /var/lib/apt/lists/*

# install apache and modules
RUN apt-get update && apt-get install -y \
    apache2 \
    libapache2-mod-fastcgi \
    libapache2-mod-xsendfile \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod \
       rewrite \
       xsendfile \
       headers \
       env \
       fastcgi \
       actions \
       remoteip \
       mime \
       dir

#RUN touch /etc/apache2/sites-available/owncloud.conf \
#    && a2ensite owncloud \
#    && a2dissite 000-default.conf

EXPOSE 80

COPY run.sh /
CMD ["/run.sh"]

