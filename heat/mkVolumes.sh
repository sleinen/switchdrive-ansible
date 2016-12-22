#!/usr/bin/env bash

#. ~/openrc/ls-drive-staging
#SITE="sldrive"
. ~/openrc/ls-drive-test
SITE="tldrive"

if true; then
	
	# graphite
	VOL_ID=`cinder create --display-name $SITE-graphite_data 100 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-graphite $VOL_ID
	
	# db1
	VOL_ID=`cinder create --display-name $SITE-db_data 100 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-db1 $VOL_ID
	
	
	# nfs
	VOL_ID=`cinder create --display-name $SITE-000 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-nfs1 $VOL_ID
	
	
	VOL_ID=`cinder create --display-name $SITE-101 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-nfs1 $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-102 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-nfs1 $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-103 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-nfs1 $VOL_ID
	VOL_ID=`cinder create --display-name $SITE-104 2048 | egrep '\| *id *\|' | sed -e 's/.*id *\| *//' -e 's/ .*//'`
	nova volume-attach $SITE-nfs1 $VOL_ID


fi 

