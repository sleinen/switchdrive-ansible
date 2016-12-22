# Ansible Playbooks for OwnCloud installation

The ansible playbooks in this repo are used at SWITCH for setting up the SWITCHdrive service. That service runs on top of SWITCHengines, an OpenStack IaaS offering from SWITCH.

## Infrastructure

At SWITCH we setup the infrastructure with the help of some heat templates which can be found in the `/heat` directory. Of course, it is possible to use these ansible playbooks with bare metal server as well. Just make sure you create a corresponding inventory file in `/inventories`

### Heat templates

In order to create/delete VM with the provided heat templates, cd to the `/heat` directory. make a copy of setup.sample:

    cp setup.sample setup

and edit the file: 

* `SSH_KEY`is the name of your ssh-key in your openstack project. 
* `NAME_PREFIX` is the prefix for every heat-stack and VM name.

Then edit the `NAME_PREFIX`.env file. 

Finally run the `./manageStack` script.

## Install Software / Configure Hosts

To run:

    ansible-playbook -i inventories/drive playbooks/site.yml

or individual server groups like so:

    ansible-playbook -i inventories/drive playbooks/webservers.yml


Environments
------------

We use several environments - you can choose which one to perform work on:

  * drive: this is production (in zürich)
  * sldrive: this is staging in lausanne
  * tldrive: testing in lausanne
  
Note: in order to setup a testing/staging environment on SWITCHengines run the Heat Template in the directory heat.

Server Types
------------

* dbservers.yml         - the Postgres Database Servers
* devservers.yml        - a Web server that is used for development it can be reached on https://drive.sitch.ch:4443/ 
* lbservers.yml         - the HAproxy Loadbalancer
* ldapservers.yml       - the LDAP server
* nfsservers.yml        - the NFS server
* webservers.yml        - the nginx/php5-fpm Web/App server combo
...


Tasks
-----

There are a number of tasks you can perform on the application:

    ansible-playbook -i inventories/drive jobs/taskname.yml

where taskname.yml is one of the following:

* maintenance_start.yml     - put ownCloud into maintenance mode
* maintenance_stop.yml      - disable ownCloud maintenance mode
* servers_start.yml         - start the web servers
* servers_stop.yml          - stop the web servers (the load balancer will show a 503 page)


Upgrade
=======
update inventories/drive -> edit "OWNCLOUD_VERSION"
ansible-playbook -i inventories/drive playbooks/devservers.yml
drive-lb: service haproxy stop
ansible-playbook -i inventories/drive jobs/servers_stop.yml
drive-dev1: /root/occ upgrade --skip-migration-test
copy 'version' info from /var/www/owncloud/config/config.php into template
ansible-playbook -i inventories/drive playbooks/webservers.yml
ansible-playbook -i inventories/drive playbooks/syncservers.yml
drive-lb: service haproxy start

