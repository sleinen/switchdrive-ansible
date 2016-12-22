#!/usr/bin/env bash

#. ~/openrc/ls-drive-staging
#SITE="sldrive"
. ~/openrc/zh-drive
SITE="drive"
SERVER="nfs4"

		
	VOL_ID=`cinder create --display-name $SITE-data-119 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-data-120 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-data-121 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-data-122 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-data-123 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-data-124 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-$SERVER $VOL_ID



