#!/usr/bin/env python

import sys
import os
import cinderclient
from cinderclient.v2 import client as cinder_client


def get_environ(key, verbose=False):
    if key not in os.environ:
        print "ERROR:", key, "not defined in environment"
        sys.exit(1)
    return os.environ[key]

def main():
    os_auth_url = get_environ('OS_AUTH_URL')
    os_username = get_environ('OS_USERNAME')
    os_password = get_environ('OS_PASSWORD')
    os_tenant_name = get_environ('OS_TENANT_NAME')
    os_region_name = get_environ('OS_REGION_NAME')

    cinder = cinder_client.Client(os_username,
                                  os_password,
                                  os_tenant_name,
                                  auth_url=os_auth_url,
                                  region_name=os_region_name)

    #for volume in cinder.volumes.list():
    #    volume_name = volume.name.rstrip() if volume.name else 'None'
    #    print "Volume: {} [{}] {}GB - {}".format(volume_name, volume.id, volume.size, volume.status.upper())
    for snapshot in cinder.volume_snapshots.list():
        snapshot_name = snapshot.name.rstrip() if snapshot.name else 'None'
        print "Snapshot: {} [{}] (Volume: [{}]) {}GB - {}".format(snapshot_name, snapshot.id, snapshot.volume_id, snapshot.size, snapshot.status.upper())

if __name__ == '__main__':
    main()
