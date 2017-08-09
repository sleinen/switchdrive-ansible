# NC Evaluation

## Setup Project in SWITCHengines

    openstack project create SWITCHdriveNC --description "Testing Nextcloud as Owncloud replacement"
    
add users:

    openstack role add --user christian.schnidrig@switch.ch --project SWITCHdriveNC _member_
    openstack role add --user christian.schnidrig@switch.ch --project SWITCHdriveNC heat_stack_owner
    
    openstack role add --user gregory.vernon@switch.ch --project SWITCHdriveNC _member_
    openstack role add --user gregory.vernon@switch.ch --project SWITCHdriveNC heat_stack_owner

    openstack role add --user thomas.buschor@switch.ch --project SWITCHdriveNC _member_
    openstack role add --user thomas.buschor@switch.ch --project SWITCHdriveNC heat_stack_owner

set project quotas:

    openstack quota set SWITCHdriveNC --os-region LS --ram 1638370 --instances 50 --cores 120 --gigabytes 100000 --floating-ips 10 --volumes 100
    openstack quota set SWITCHdriveNC --os-region ZH --ram 1638370 --instances 50 --cores 120 --gigabytes 100000 --floating-ips 10 --volumes 100
    
    openstack quota show SWITCHdriveNC --os-region ZH
    openstack quota show SWITCHdriveNC --os-region LS

give access to special flavors: (has to be done as user admin in zh and ls regions)

    openstack flavor list --all | grep ssd
    openstack flavor set --project SWITCHdriveNC drive-100-32-8-100-ssd
    openstack flavor set --project SWITCHdriveNC drive-40-4-4


# Prepare ansible repo

Create files:
- inventories/nzdrive
- vars/servers.nzdrive
- vars/group_vars/all/user

for nzdrive a chose a service name of drive-nc.switch.ch. For nldrive, that would have to be something different.

# create network & jumphost & jump-ip

    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -t os_network
    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -t os_sec_group
    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -e server=jumphost1 -t os_server_all
    
get floating ip allocated:

    openstack floating ip list
    
edit `vars/servers.nzdrive` and add floating ip info for jumphost1

edit `inventories/nzdrive` and replace address for jumphost1


if for some reason you prefer to manually add a floating ip:

    openstack server add floating ip nzdrive-jumphost1 86.119.33.56
    
## give access to docker registry

edit security group of project SWITCHdrive (yes not a typo) named Docker Registry and add floating ip as well as ip of router.

to find ip of router run:

    openstack router list
    openstack router show <router-id>
    
The ip can be found in `external_gateway_info`
    
# install jumphost

    ansible-playbook -i inventories/nzdrive playbooks/jumphost.yml

# create common infrastructure (security goups, server groups, vips)

    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -t os_sec_group,os_server_group,os_vip

or simply: (will try recreating network, but that is fine)

    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml
    
list the groups and replace the ids in servers.nzdrive.yml` -> os_server_group

# create all other servers

    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -e server=db1,nfs1,web1,web2,sync1,sync2,lb1,redis1 -t os_server_all

# create and attach data volumes

    ansible-playbook -i inventories/nzdrive jobs/infra_create.yml -e server=nfs1 -t os_data

# install db server

    ansible-playbook -i inventories/nzdrive playbooks/mariadbservers.yml

This may hang. Then ^C and run 

    ansible-playbook -i inventories/nzdrive jobs/mariadb_initdb.yml
    ansible-playbook -i inventories/nzdrive jobs/mariadb_boot_single_node_cluster.yml
    
Setting up the db for the first time is a brittle step and may go wrong several times in a row just run initdb several times until it is ok.
Beware: /mnt/data/mariadb/tmp might not have the right permissions


## create db

Normally the steps above create an owncloud db ready to be used. However in this sharded setup we need dbs a01 ... a20. One for each shard.
Let's create them manually:

    ssh db1.nzdrive
    sudo -i
    /root/mariadb
    
    CREATE DATABASE IF NOT EXISTS `a01` ;
    GRANT ALL ON `a01`.* TO 'owncloud'@'%' ;
    FLUSH PRIVILEGES ;

This, of course is best done as a SQL script, and sourced whilst in mariadb.

# install nfs and redis servers

    ansible-playbook -i inventories/nzdrive playbooks/nfsservers.yml

    ansible-playbook -i inventories/nzdrive playbooks/redisservers.yml

# install web and sync servers

Add section config for new site to `group_vars/all/shards`
Add templates for new site to `roles/ocphp_fpm/templates/owncloud`
Add templates for new site to `roles/ocapache/templates`

    ansible-playbook -i inventories/nzdrive playbooks/webservers.yml
    ansible-playbook -i inventories/nzdrive playbooks/syncservers.yml

# install lb server

add section in group_vars/all/keepalived.yml for the new site.
add template for new site to 'roles/haproxy/templates'
edit file `group_vars/all/certificates` add new service name to `service_cert` dictionary. 
Leave it empty we'll create a cert with letsencrypt but we first want it to create a self signed cert to get started.

    ansible-playbook -i inventories/nzdrive playbooks/lbservers.yml --limit=\*1

# DNS and Service IP & certificate

## ip

Get a floating ip and assign it to lb_vip1.
Since we only have one lb here. I assigned it to lb1 directly instead of the lb_vip1. (for testing nc that is good enough)

# DNS
Get DNS entry for that ip. For the site nzdrive I chose 'drive-nc.switch.ch'. 
(don't know yet what the requirements for lausanne by nextcloud are going to be....)

## certificate
Once we have dns entry, we can request a letsencrypt certificate. 

edit file `group_vars/all/defaults` add section in `letsencrypt.domain`

install letsencrypt docker container:

    ansible-playbook -i inventories/nzdrive playbooks/letsencrypt.yml --limit=*1

run letsencrypt:

    ssh lb1.nzdrive
    sudo docker start -a letsencrypt
    sudo cat /etc/letsencrypt/live/drive-nc.switch.ch/fullchain.pem /etc/letsencrypt/live/drive-nc.switch.ch/privkey.pem > /etc/haproxy/ssl/drive-nc.switch.ch.pem
    sudo docker restart haproxy
    
Whatch output and check for errors.

open `https://drive-nc.switch.ch/` in a browser -> you should have a working certificate.

# install owncloud

Set installed flag in config back to false: edit `shards` file -> in dictionary `shard_config.<service_name>` change `installed` to false

    ansible-playbook -i inventories/nzdrive playbooks/webservers.yml --limit=*1 -t ocphp_fpm
    
installation with occ command seems to be broken -> install through the web:

first shut down apache on web2 to make sure it does not interfere
    ssh web2.nzdrive sudo docker stop ocapache
    
In a browser load `https://drive-nc.switch.ch/`

-> login with credentials from the file web1.nzdrive:/etc/owncloud/autoconfig.a01.php

edit `shards` file -> in dictionary `shard_config.<service_name>` change `installed` to true

start web2 again
    ssh web2.nzdrive sudo docker start ocapache


## disable silly apps

    ssh web1.nzdrive
    SHARD=a01
    
    /root/occ $SHARD app:enable  user_ldap
    /root/occ $SHARD app:disable activity
    /root/occ $SHARD app:disable comments
    /root/occ $SHARD app:disable firewall
    /root/occ $SHARD app:disable systemtags
    /root/occ $SHARD app:disable windows_network_drive
    /root/occ $SHARD app:disable workflow


# Missing
login as admin and setup ldap. -> do not run ldap ansible playbooks. That is something different.

replace ocphp_fpm docker image with a nc image (needs to be build first).
