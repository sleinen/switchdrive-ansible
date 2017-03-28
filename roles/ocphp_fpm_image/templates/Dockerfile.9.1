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
# apps

# impersonate
RUN curl -L https://github.com/owncloud/impersonate/archive/master.zip > /tmp/impersonate.zip \
    && unzip -d /var/www/owncloud/apps /tmp/impersonate.zip \
    && mv /var/www/owncloud/apps/impersonate-master /var/www/owncloud/apps/impersonate \
    && rm /tmp/impersonate.zip

###########
# themes

RUN curl -L https://{{git_hub_user}}:{{git_hub_passwd}}@github.com/switch-ch/switch-owncloud-theme/archive/master.zip > /tmp/themes.zip \
    && unzip -d /var/www/owncloud/themes /tmp/themes.zip \
    && mv /var/www/owncloud/themes/switch-owncloud-theme-master/ /var/www/owncloud/themes/switch \
    && rm /tmp/themes.zip

###########
# install from a git branch

{{ comment_out_git_include }}ENV ARCHIVE=/tmp/branch.zip
{{ comment_out_git_include }}RUN curl -L {{ git_branch }} > $ARCHIVE \
{{ comment_out_git_include }}    && unzip -d /tmp /$ARCHIVE \
{{ comment_out_git_include }}    && cd /tmp/core*/ \
{{ comment_out_git_include }}    && rm -rf autotest* build/ tests/ \
{{ comment_out_git_include }}    && tar -cf - * | tar -xf - -C /var/www/owncloud \
{{ comment_out_git_include }}    && rm -rf $ARCHIVE /tmp/core*/

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
