
#. ~/rc/zh-drive
#openstack snapshot list| grep backup-drive-data-| grep "deleting" |grep '2015'| awk '{ print $2 }' > ./snap-list
openstack snapshot list| grep backup-drive-data | grep error | awk '{ print $2 }'

. ~/rc/zh-peta

for snap in `cat ./snap-list`; do 
  cinder snapshot-reset-state --state available $snap
  openstack snapshot delete $snap
  sleep 1
done


-------------
. ~/rc/zh-drive
openstack snapshot list| grep backup-drive-data- | grep -- -201601 | awk '{ print $2 }'> snap-list2

for snap in `cat ./snap-list2`; do 
  openstack snapshot delete $snap
  sleep 2
done

