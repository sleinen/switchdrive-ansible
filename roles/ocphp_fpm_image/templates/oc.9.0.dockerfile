FROM ubuntu:{{owncloud_ubuntu_base_version[owncloud_major_version]}}

MAINTAINER Christian Schnidrig

###########
# php-fpm

RUN apt-get update && apt-get install -y \
       "php(5-|-)fpm" \
       php-xdebug \
       php7.0-dev \
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

# appconfig
COPY patches/appconfig/lib/private/appconfig.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/appconfig.php

# ocdata
COPY patches/ocdata/lib/private/util.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/util.php

# username
COPY patches/username/remote.{{owncloud_major_version}}.php /var/www/owncloud/remote.php
COPY patches/username/base.{{owncloud_major_version}}.php /var/www/owncloud/lib/base.php
COPY patches/username/v1.{{owncloud_major_version}}.php /var/www/owncloud/ocs/v1.php

# master_password
COPY patches/masterpasswd/apps/user_ldap/user_ldap.php /var/www/owncloud/apps/user_ldap/user_ldap.php

# looping
COPY patches/looping/*.patch /
RUN cd /var/www/owncloud && \
    patch -p1 < /28320.patch && \
    patch -p1 < /28322.patch && \
    patch -p1 < /patch.patch && \
    rm /*.patch

# mimetypes
COPY patches/mimetype/mimetype.patch /
RUN cd /var/www/owncloud && patch -p1 -R < /mimetype.patch && rm /mimetype.patch

#indexes
COPY patches/index/lib/private/files/cache/cache.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/files/cache/cache.php
COPY patches/index/lib/private/group/database.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/group/database.php
COPY patches/index/lib/private/user/database.{{owncloud_major_version}}.php /var/www/owncloud/lib/private/user/database.php

#reconnect
COPY patches/reconnect/apps/dav/lib/connector/sabre/file.{{owncloud_major_version}}.php /var/www/owncloud/aps/dav/lib/connector/sabre/file.php

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
