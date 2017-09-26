# How to add IPv6 support to a site

## Tasks on SWITCHengines

first add a subnet to the existing network:

    ~> openstack subnet create \
     --ip-version 6 \
     --ipv6-ra-mode dhcpv6-stateful \
     --ipv6-address-mode dhcpv6-stateful \
     --subnet-pool tinypool \
     --network drive \
     drive-drive_subnet_ipv6
    +-------------------+------------------------------------------------------------+
    | Field             | Value                                                      |
    +-------------------+------------------------------------------------------------+
    | allocation_pools  | 2001:620:5ca1:1ee::2-2001:620:5ca1:1ee:ffff:ffff:ffff:ffff |
    | cidr              | 2001:620:5ca1:1ee::/64                                     |
    | created_at        | 2017-09-26T18:52:06Z                                       |
    | description       |                                                            |
    | dns_nameservers   |                                                            |
    | enable_dhcp       | True                                                       |
    | gateway_ip        | 2001:620:5ca1:1ee::1                                       |
    | headers           |                                                            |
    | host_routes       |                                                            |
    | id                | b2a51d04-b6f5-4082-8a26-df0bfb2b84f4                       |
    | ip_version        | 6                                                          |
    | ipv6_address_mode | dhcpv6-stateful                                            |
    | ipv6_ra_mode      | dhcpv6-stateful                                            |
    | name              | drive-drive_subnet_ipv6                                    |
    | network_id        | e5b85444-f3c0-4609-af7b-39e7eb04d45d                       |
    | project_id        | bdf747f88fee4b5a9faca3da7c26754c                           |
    | project_id        | bdf747f88fee4b5a9faca3da7c26754c                           |
    | revision_number   | 2                                                          |
    | service_types     |                                                            |
    | subnetpool_id     | 09570f12-c311-4d08-8b0c-5b8317421805                       |
    | updated_at        | 2017-09-26T18:52:06Z                                       |
+-------------------+------------------------------------------------------------+

Then attach it to your router:

    openstack router add subnet drive drive-drive_subnet_ipv6
 
Ask SWITCHengines operations to install a route for your new network.   


Fix all security groups and add ipv6 rules.


## Tasks on SWITCHdrive itself
   
Add the prefix (here `2001:620:5ca1:1ee:`) to your inventory. Variable `ipv6_prefix`.

- make sure haproxy supports ipv6 and install fixed config.


    ansible-playbook -i inventories/drive playbooks/lbservers.yml -t haproxy
    
- recreate lb servers and vips


    ansible-playbook -i inventories/drive jobs/infra_recreate.yml -e server=lb2 -t os_server,os_port
    ansible-playbook -i inventories/drive jobs/infra_recreate.yml -t os_vip
    ansible-playbook -i inventories/drive jobs/infra_recreate.yml -e server=lb1 -t os_server,os_port
    ansible-playbook -i inventories/drive jobs/infra_recreate.yml -t os_vip
    
- configure lbservers for ipv6


    ansible-playbook -i inventories/drive playbooks/lbservers.yml -t ipv6


- fix keepalived config on lbservers.


    ansible-playbook -i inventories/drive playbooks/lbservers.yml -t keepalived


## DNS

add the new ipv6 addresses to your DNS


.