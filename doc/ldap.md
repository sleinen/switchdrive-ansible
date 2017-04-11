# usefull commands:

## list admin users:

    ldapsearch -H ldapi:// -LLL -Q -Y EXTERNAL -b "cn=config" "(olcRootDN=*)" dn olcRootDN olcRootPW

### update admin password:

    slappasswd


    ldapmodify -Y EXTERNAL -H ldapi:/// << END
    dn: olcDatabase={1}hdb,cn=config
    replace: olcRootPW
    olcRootPW: {SSHA}TsB0nqowBLaDxQOqrRJYpoyJshMEIACN
    END

now both passwords will work until you do:

    ldapmodify  -H ldap://localhost:389/ -D "cn=admin,dc=cloud,dc=switch,dc=ch" -w "new_passwd" << END
    dn: cn=admin,dc=cloud,dc=switch,dc=ch
    changetype: modify
    replace: userPassword
    userPassword: new_passwd

    END


auf owncloud web server:

    /root/occ a01 ldap:set-config s01 ldapAgentPassword "new_passwd"

## search a user by uid:

    ldapsearch -H ldap://localhost:389/ -D "cn=admin,dc=cloud,dc=switch,dc=ch" -w "passwd" -b "dc=cloud,dc=switch,dc=ch" uid=christian.schnidrig@switch.ch

## get entryUUID:

    ldapsearch -H ldap://localhost:389/ -D "cn=admin,dc=cloud,dc=switch,dc=ch" -w "passwd" -b "dc=cloud,dc=switch,dc=ch" uid=christian.schnidrig@switch.ch entryUUID

# clone ldap server (for staging)

Run this on staging server:

- purge ldap server:


    dpkg --purge slapd
    rm -rf /var/lib/ldap
    rm -rf /etc/ansible/.done/ldap

- run ansible:


    ansible-playbook -i inventories/sldrive playbooks/ldapservers.yml -t ldap


On production server:

- create backup files:

    #slapcat -n 0 -l /tmp/ldap.config.ldif
    slapcat -n 1 -l /tmp/ldap.data.ldif

copy files to staging server: ~ubuntu

    service slapd stop
    #rm -rf /etc/ldap/slapd.d/*
    rm -rf /var/lib/ldap/*
    #sudo -u openldap slapadd -n 0 -F /etc/ldap/slapd.d -l ~ubuntu/ldap.config.ldif
    sudo -u openldap slapadd -n 1 -F /etc/ldap/slapd.d -l ~ubuntu/ldap.data.ldif
