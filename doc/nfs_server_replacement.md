# Replace NFS1

## prepare (day before)

- add new data disk:


    - { name: "data_new", name_prefix: "data", state: "mounted", device: "/dev/vdo", size: "2048", fs: "xfs", owner: "www-data", group: "www-data", mode: "0770", ocdata_link: "107"  }

 run:

    ansible-playbook -i inventories/drive jobs/infra_create.yml -e server=nfs1 -t os_data
    ansible-playbook -i inventories/drive playbooks/nfsservers.yml --limit=*71 -t mount


- evacuate all users: (make sure to configure it such that it'll do the right thing)


    /root/manageUserDirs.py --instance evacuate

- setup new nfs servers: nfs8,nfs9 with no disks.


    ansible-playbook -i inventories/drive jobs/infra_create.yml -e server=nfs8,nfs9 -t os_server_all
    apt-get update & apt-get dist-upgrade
    ansible-playbook -i inventories/drive playbooks/nfsservers.yml --limit=*78,*79

- kill the servers again, but not the root volumes!


    ansible-playbook -i inventories/drive jobs/infra_delete.yml -e server=nfs8,nfs9 -t os_server,os_port


- set all nfs volumes to "absent" in `servers.drive.yml`


## Do the replacement

- Shutdown SWITCHdrive:

    ansible-playbook -i inventories/drive jobs/php_fpm_stop.yml

- Twitter: "we are experiencing a problem with our storage system. We are working on fixing it."

- Make sure no move user jobs are running on mgmt.

- sync data (nfs1)

    /usr/bin/rsync -axS --delete --stats /mnt/data/ /mnt/data_new

- unmount nfs volumes on all app servers:

    ansible-playbook -i inventories/drive playbooks/{web,sync,dev,mgmt}servers.yml -t mount

- verify on app servers that volumes are unmounted and /etc/fstab is cleared out.


- kill nfs1,nfs2: (they were created using heat -> delete them using heat..)


    SWITCHdrive:ZH@:~/drive2/heat> ./manageStack -dv nfs1,nfs2

- clear out `/etc/fstab` on nfs6,nfs7
- kill nfs6,nfs7: (we still need root volume nfs6)


    ansible-playbook -i inventories/drive jobs/infra_delete.yml -e server=nfs6,nfs7 -t os_server,os_port

- rename root volumes:


    os volume list | egrep 'drive-nfs.*_root'
    os volume set --name drive-nfs1_root drive-nfs8_root
    os volume set --name drive-nfs2_root drive-nfs9_root


- rename data volumes:
    
    
    os volume list | egrep data-data
    os volume set --name drive-data-data_old drive-data-data
    os volume set --name drive-data-data drive-data-data_new


- fix servers.drive.yml (correct disk with correct oc_data links)


- rebuild nfs1,2,6:


    ansible-playbook -i inventories/drive jobs/infra_create.yml -e server=nfs1,nfs2,nfs6 -t os_server_all,os_data

- patch engines (max_files limit on hypervisors with the newly created servers nfs1,2)
  - get hypervisor name
    
    
    . ~/rc/zh-drive
    os server list | egrep 'nfs(1|2)'
    . ~/rc/zh-peta
    os server show <ID> | grep hypervisor_hostname      

- - edit qemu.conf and change `max_files` from 8191 to 32767
    

    ssh zhdk00XX.zhdk.cloud.switch.ch
        sudo puppet agent --disable "Workaround for issue with instances with lots of RBD devices"
        sudo vi /etc/libvirt/qemu.conf
        sudo systemctl restart libvirt-bin

- - restart VM 
  
     
    openstack server reboot --hard drive-nfs1
    openstack server reboot --hard drive-nfs2

-  - check with: `cat /proc/XXX/limits`
  

- check and fix label of data volume on nfs1:


    xfs_admin -l /dev/vdb
    xfs_admin -L "data" /dev/vdb
    xfs_admin -l /dev/vdb

- remount disks, fix ocdata links:


    ansible-playbook -i inventories/drive playbooks/nfsservers.yml -t mount,export,ocdata


- check all is ok 

- restart service:


    ansible-playbook -i inventories/drive jobs/php_fpm_restart.yml


- Twitter: "SWITCHdrive is running normally"
