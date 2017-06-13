# Ansible Playbooks for OwnCloud installation

The ansible playbooks in this repo are used at SWITCH for setting up the SWITCHdrive service. That service runs on top of SWITCHengines, an OpenStack IaaS offering from SWITCH.

## Infrastructure

At SWITCH we used to setup the infrastructure with the help of some heat templates which can be found in the `/heat` directory. We are currently migrating this to ansible: see also `vars/servers.drive.yml` and `jobs/infra_*`.

Of course, it is possible to use the ansible playbooks in this repo with bare metal server as well. Just make sure you create a corresponding inventory file in `inventories`


### Environments

We use several environments - you can choose which one to perform work on:

  * drive: this is production (in zürich)
  * sldrive: this is staging in lausanne
  * tldrive: testing in lausanne


### Setup new servers

#### Heat templates (deprecated)
**For new servers use `jobs/infra_*` ansible playbooks instead**.
Ansible recently added support for openstack. Since ansible fits in much better in this repo we gave up on heat.
Whenever a server needs to be replaced. Delete it using heat and then setup new server with ansible.

In order to create/delete VM with the provided heat templates, cd to the `/heat` directory. make a copy of setup.sample:

    cp setup.sample setup

and edit the file:

* `SSH_KEY`is the name of your ssh-key in your openstack project.
* `NAME_PREFIX` is the prefix for every heat-stack and VM name.

Then edit the `NAME_PREFIX`.env file.

Finally run the `./manageStack` script.

#### Ansible

##### Add server

Update the files:
- `vars/servers.<site>.yml` and add server config line (`os_server` variable)
- `inventory/<site>` and add entry for server

Run

    ansible-playbook -i inventories/<site> jobs/infra_create.yml -e server=<server_name> [-t os_server_all]


## Install Software / Configure Hosts


    ansible-playbook -i inventories/drive playbooks/<server_type_playbook>.yml [-t <server_inventory_name>]



### Server Types

* dbservers.yml         - the Postgres Database Servers
* lbservers.yml         - the HAproxy Loadbalancer
* ldapservers.yml       - the LDAP server
* nfsservers.yml        - the NFS server
* webservers.yml        - the nginx/php5-fpm Web/App server combo
...
* devservers.yml        - a Web server that is used for development it can be reached on https://drive.sitch.ch:4443/


### Tasks

There are a number of tasks you can perform on the application:

    ansible-playbook -i inventories/drive jobs/<taskname>.yml

where `<taskname>.yml` is one of the following:

* maintenance_start.yml     - put ownCloud into maintenance mode
* maintenance_stop.yml      - disable ownCloud maintenance mode
* servers_start.yml         - start the web servers
* servers_stop.yml          - stop the web servers (the load balancer will show a 503 page)
* many others...
