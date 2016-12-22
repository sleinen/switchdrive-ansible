#!/bin/bash

rate=`echo "show stat " | nc -U /var/lib/haproxy/stats | grep -i backend |awk -F"," '{print $34}'| tr -d ' '`

rate_max=`echo "show stat " | nc -U /var/lib/haproxy/stats | grep -i backend |awk -F"," '{print $36}'| tr -d ' '`

SslRate=`echo "show info" | nc -U /var/lib/haproxy/stats | grep SslRate:|head -n1 |awk -F":" '{print $2}'| tr -d ' '`

ConnRate=`echo "show info" | nc -U /var/lib/haproxy/stats | grep ConnRate:|head -n1 |awk -F":" '{print $2}'| tr -d ' '`

CurrConns=`echo "show info" | nc -U /var/lib/haproxy/stats | grep CurrConns:|head -n1 |awk -F":" '{print $2}'| tr -d ' '`

CurrSslConns=`echo "show info" | nc -U /var/lib/haproxy/stats | grep CurrSslConns:|head -n1 |awk -F":" '{print $2}'| tr -d ' '
`

rval=`echo $?`

Perf="|rate=${rate};;;0;100 rate_max=${rate_max};;;0;100 ConnRate=${ConnRate};;;0;100 SslRate=${SslRate};;;0;1
00 CurrConns=${CurrConns};;;0;100 CurrSslConns=${CurrSslConns};;;0;100"

#echo $Perf
#echo $SslRate

Initial="rate=${rate},rate_max=${rate_max},ConnRate=${ConnRate},SslRate=${SslRate},CurrConns=${CurrConns},Curr
SslConns=${CurrSslConns}"

if [ "$rval" -eq 0 ]; then
        echo $Initial$Perf  
        exit 0
fi

echo "WARNING, NO HAPROXY INFO WAS FOUND"
exit 1
