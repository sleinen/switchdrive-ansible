#!/usr/bin/env bash

set -x

cp "/etc/owncloud/php.fpm.{{owncloud_version}}.ini" "{{owncloud_php_conf_dir[owncloud_major_version]}}/fpm/php.ini"
cp "/etc/owncloud/php.cli.{{owncloud_version}}.ini" "{{owncloud_php_conf_dir[owncloud_major_version]}}/cli/php.ini"
cp "/etc/owncloud/php-fpm.{{owncloud_version}}.conf" "{{owncloud_php_conf_dir[owncloud_major_version]}}/fpm/php-fpm.conf"
cp "/etc/owncloud/fpm_pool_owncloud.{{owncloud_version}}.conf" "{{owncloud_php_conf_dir[owncloud_major_version]}}/fpm/pool.d/owncloud.conf"

for shard in $SHARDS; do
	if [ `egrep "{{owncloud_version}}-{{owncloud_docker_image_version}}" "{{owncloud_webroot}}/${shard}_version"  | wc -l` -eq 0 ]; then
		rm -rf "{{owncloud_webroot}}/${shard}" 2>/dev/null
		mkdir -p "{{owncloud_webroot}}/${shard}"
		tar cf - --one-file-system -C "/var/www/owncloud" . | tar xf - -C "{{owncloud_webroot}}/${shard}"
		echo "{{owncloud_version}}-{{owncloud_docker_image_version}}" > "{{owncloud_webroot}}/${shard}_version" 
	fi
	cp "/etc/owncloud/autoconfig.${shard}.php" "{{owncloud_webroot}}/${shard}/config/autoconfig.php"
    cp "/etc/owncloud/config.${shard}.php" "{{owncloud_webroot}}/${shard}/config/config.php"
    cp "/etc/owncloud/cluster.config.${shard}.php" "{{owncloud_webroot}}/${shard}/config/cluster.config.php"
	chown -R www-data:www-data "{{owncloud_webroot}}/${shard}/config"
	rm "{{owncloud_webroot}}/${shard}.php-fpm.sock"
	ln -s "/var/run/php/php-fpm.{{owncloud_version}}-{{owncloud_docker_image_version}}.sock" "{{owncloud_webroot}}/${shard}.php-fpm.sock"
done

exec "$@"
