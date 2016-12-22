#!/bin/bash

start() {
    echo "Starting server..."
    sudo -u _graphite /usr/bin/python /usr/lib/python2.7/dist-packages/graphite/manage.py syncdb --noinput
    service carbon-cache start
	/usr/sbin/apache2ctl start
}

stop() {
    echo "Stopping server..."
    service carbon-cache stop
    /usr/sbin/apache2ctl stop
    exit
}

trap stop INT TERM

start

sleep infinity

stop
