#!/bin/bash

start() {
    echo "Starting server..."
    sudo -u _graphite /usr/bin/python /usr/lib/python2.7/dist-packages/graphite/manage.py syncdb --noinput
    service carbon-cache start
    /usr/bin/carbon-relay --config=/etc/carbon/carbon.conf --pidfile=/var/run/carbon-relay.pid --logdir=/var/log/carbon/ start
	  /usr/sbin/apache2ctl start
}

stop() {
    echo "Stopping server..."
    /usr/bin/carbon-relay --config=/etc/carbon/carbon.conf --pidfile=/var/run/carbon-relay.pid --logdir=/var/log/carbon/ stop
    service carbon-cache stop
    /usr/sbin/apache2ctl stop
    exit
}

trap stop INT TERM

start

sleep infinity

stop
