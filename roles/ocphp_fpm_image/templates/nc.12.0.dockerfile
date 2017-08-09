FROM ubuntu:{{nc_ubuntu_base_version[owncloud_major_version]}}

MAINTAINER Christian Schnidrig

###########
# php-fpm

RUN apt-get update && apt-get install -y \
       "php(5-|-)fpm" \
       php-xdebug \
    && rm /etc/php/7.0/fpm/pool.d/www.conf || true \
    && rm /etc/php5/fpm/pool.d/www.conf || true \
    && rm -rf /var/lib/apt/lists/*

###########
# prepare apt / basic packages

RUN apt-get update && apt-get install -y \
       apt-transport-https \
       curl \
       vim \
       zip \
       bzip2 \
       wget \
       {{nc_pkgs[owncloud_major_version]}} \
    && rm -rf /var/lib/apt/lists/*

###########
# install owncloud

RUN wget https://download.nextcloud.com/server/releases/nextcloud-{{owncloud_version}}.tar.bz2 && \
    wget https://download.nextcloud.com/server/releases/nextcloud-{{owncloud_version}}.tar.bz2.asc && \
    wget https://nextcloud.com/nextcloud.asc  && \
    gpg --import nextcloud.asc  && \
    gpg --verify nextcloud-{{owncloud_version}}.tar.bz2.asc nextcloud-{{owncloud_version}}.tar.bz2 && \
    tar -xjf nextcloud-{{owncloud_version}}.tar.bz2 && \
    mkdir -p /var/www && \
    mv nextcloud /var/www/owncloud && \
    rm nextcloud-{{owncloud_version}}.tar.bz2 nextcloud-{{owncloud_version}}.tar.bz2.asc

###########
# apps

# globalsiteselector

RUN curl -L https://github.com/nextcloud/globalsiteselector/archive/master.zip > /tmp/gss.zip && \
    unzip -d /var/www/owncloud/apps /tmp/gss.zip && \
    mv /var/www/owncloud/apps/globalsiteselector* /var/www/owncloud/apps/globalsiteselector && \
    rm /tmp/gss.zip

###########
# themes

#RUN curl -L https://{{git_hub_user}}:{{git_hub_passwd}}@github.com/switch-ch/switch-owncloud-theme/archive/master.zip > /tmp/themes.zip \
#    && unzip -d /var/www/owncloud/themes /tmp/themes.zip \
#    && mv /var/www/owncloud/themes/switch-owncloud-theme-master/ /var/www/owncloud/themes/switch \
#    && rm /tmp/themes.zip

###########
# patches

# ocdata
#COPY patches/ocdata/lib/private/util.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/util.php

###########
# config

COPY user.ini /var/www/owncloud/.user.ini

###########
# fix permissions

RUN chown -R www-data:www-data /var/www/owncloud \
    && chown root:www-data /var/www/owncloud \
    && mkdir -p /var/www/owncloud/assets \
    && chown www-data:www-data /var/www/owncloud/assets \
    && chown root:www-data /var/www/owncloud/.htaccess \
    && chmod u=rw,g=r,o=r /var/www/owncloud/.htaccess \
    && chown root:www-data /var/www/owncloud/.user.ini \
    && chmod u=rw,g=r,o=r /var/www/owncloud/.user.ini \
    && chmod u=rx,g=rx,o=rx /var/www/owncloud/occ

###########
# log dir

RUN mkdir -p /var/log/owncloud \
    && chown www-data:www-data /var/log/owncloud

###########
# export volume for apache container

COPY php/cli/conf.d/30-owncloud.ini {{nc_php_conf_dir[owncloud_major_version]}}/cli/conf.d/30-owncloud.init

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["{{nc_php_fpm[owncloud_major_version]}}", "-F"]
