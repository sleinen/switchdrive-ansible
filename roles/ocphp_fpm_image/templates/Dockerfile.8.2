FROM ubuntu:{{owncloud_ubuntu_base_version[owncloud_major_version]}}

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
    && curl {{owncloud_repo_base_url}}/Release.key > /tmp/Release.key \
    && apt-key add - < /tmp/Release.key \
    && echo 'deb {{owncloud_repo_base_url}}/ /' >> /etc/apt/sources.list.d/owncloud.list \
    && rm -rf /var/lib/apt/lists/* /tmp/Release.key

###########
# install owncloud

RUN apt-get update && apt-get install -y \
       {{owncloud_pkgs[owncloud_major_version]}} \
    && rm -rf /var/lib/apt/lists/*


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
