openstack server add security group e60d8afa-2a8b-4e3c-ae2d-22111786d03f 6cb6a5f2-7ecf-462f-8493-cb5a523f6419
openstack server add security group a5ffd219-1444-45c4-b995-e429544833c9 6cb6a5f2-7ecf-462f-8493-cb5a523f6419
# Remove the internal security group
openstack server remove security group e60d8afa-2a8b-4e3c-ae2d-22111786d03f a3bc3bf1-129a-4bea-adaf-eb915676192e 
openstack server remove security group a5ffd219-1444-45c4-b995-e429544833c9 a3bc3bf1-129a-4bea-adaf-eb915676192e 
