FROM ubuntu:{{owncloud_ubuntu_base_version[owncloud_major_version]}}

MAINTAINER Fergus Kerins

###########
# php-fpm

RUN apt-get update && apt-get install -y \
       php7.0-fpm \
       #"php(5-|-)fpm" \
       openssl \
       php-imagick \
       php7.0-common \
       php7.0-curl \
       php7.0-gd \
       php7.0-imap \
       php7.0-intl \
       php7.0-json \
       php7.0-ldap \
       php7.0-mbstring \
       php7.0-mcrypt \
       php7.0-mysql \
       php7.0-pgsql \
       php-smbclient \
       php-ssh2 \
       php7.0-sqlite3 \
       php7.0-xml \
       php7.0-zip \
       php-apcu \
       php7.0-dev \
       php-pear \
       php-bz2 \
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
    && curl {{owncloud_repo_base_url}}/Release.key > /tmp/Release.key \
    && apt-key add - < /tmp/Release.key \
    && echo 'deb {{owncloud_repo_base_url}}/ /' >> /etc/apt/sources.list.d/owncloud.list \
    && rm -rf /var/lib/apt/lists/* /tmp/Release.key

###########
# newest php-redis

RUN yes '' | pecl install redis && \
    echo "extension=redis.so\n" > /etc/php/7.0/mods-available/redis.ini && \
    cp /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/cli/conf.d/redis.ini && \
    cp /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/redis.ini

###########
# install owncloud

RUN apt-get update && apt-get install -y \
       {{owncloud_pkgs[owncloud_major_version]}} \
    && rm -rf /var/lib/apt/lists/*

###########
# apps

###########
# themes

RUN curl -L https://{{git_hub_user}}:{{git_hub_passwd}}@github.com/switch-ch/switch-owncloud-theme/archive/master.zip > /tmp/themes.zip \
    && unzip -d /var/www/owncloud/themes /tmp/themes.zip \
    && mv /var/www/owncloud/themes/switch-owncloud-theme-master/ /var/www/owncloud/themes/switch \
    && rm /tmp/themes.zip

###########
# patches

# ocdata
COPY patches/ocdata/lib/private/util.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/legacy/util.php

# username
COPY patches/username/remote.{{owncloud_major_version}}.php /var/www/owncloud/remote.php
COPY patches/username/base.{{owncloud_major_version}}.php /var/www/owncloud/lib/base.php
COPY patches/username/v1.{{owncloud_major_version}}.php /var/www/owncloud/ocs/v1.php

# master_password
COPY patches/masterpasswd/apps/user_ldap/User_LDAP.10.0.php /var/www/owncloud/apps/user_ldap/lib/User_LDAP.php


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

COPY php/cli/conf.d/30-owncloud.ini {{owncloud_php_conf_dir[owncloud_major_version]}}/cli/conf.d/30-owncloud.init

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["{{owncloud_php_fpm[owncloud_major_version]}}", "-F"]
