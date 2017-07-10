#!/bin/bash

. /etc/apache2/envvars

get rid of pid file
rm /var/run/apache2/apache2.pid > /dev/null 2>&1

exec /usr/sbin/apache2 -DFOREGROUND


