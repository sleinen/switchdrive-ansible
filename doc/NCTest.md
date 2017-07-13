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
- vars/group_vars/user

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

    ansible-playbook -i inventories/nzdrive playbooks/lbservers.yml --limit=*1

# service ip

get a floating ip and assign it to lb_vip1 (took shortcut and assigned it to lb1 since we only have one load balancer anyways.)

get DNS entry for that ip. Name 'drive-nc.switch.ch'. (don't know yet what the requirements for lausanne by nextcloud are going to be....)

Once we have dns entry, we can request a letsencrypt certificate. 

Other stuff missing is: create db for shard a01, setup ldap config in db etc.

replace ocphp_fpm with no comment stuff.