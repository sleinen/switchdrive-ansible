# Storage Setup

This document describes how SWITCHdrive stores its users' files.

## Overview

As shown in the _Architecture Overview_ (a link to diagram would be
nice, but I only found that on the internal Wiki-- SL.), application
servers (sync/web) access user files via _NFS servers_.  Each of these
NFS servers mount and export multiple _user file systems_.  These user
file systems are backed by _data volumes_ implemented as _RBD images_
in a large Ceph storage cluster.

### NFS

SWITCHdrive includes a number (currently four) NFS servers, each of
which exports a number of data volumes (currently 20–23).  Each NFS
client (currently four web, four sync, one management, and one other
node) mount all (currently 83) file systems from the NFS servers,
driven by entries in their `/etc/fstab` files.

On the NFS clients, several options are specified for the NFS mounts
of user data file systems, mostly to improve performance:
`noatime,async,rsize=1048576,wsize=1048576`.

The protocol used is NFS v4 over TCP.  There is a single TCP
connection for each client/server combination, over which requests for
all file systems are multiplexed.

### Rados

Rados is the low-level distributed storage layer in Ceph.  Access to
Rados is based on named storage objects.  The objects are stored
within "OSDs" (Object Storage Daemons) distributed throughout the
storage cluster.  Typically, there is one OSD for each storage device
(e.g. disk drive).  For example, the Ceph cluster that the production
SWITCHdrive system runs on consists of 476 OSDs—48 servers with 10
disk each, minus four disks that were decommissioned.  Common state
such as the "map" of OSDs and their state are stored in a distributed
database consisting of "mon" (or "monitor") servers, with consistency
guaranteed by an implementation of the well-known _Paxos_ protocol.

Clients can map object names to OSDs using a consistent hash function
called CRUSH.  Therefore, clients can usually talk to OSDs directly to
access data, without having to go through some kind of separate
metadata server.

### RBD

RBD (Remote Block Device) is one of the possible ways to access a Ceph
cluster.  It is based on the model of a _block device_ such as a hard
disk, which can be seen as a large (usually Gigabytes, Terabytes or
even larger) contiguous sequence of bytes that is usually read from or
written to as _blocks_ of some size, typically 512 or 4096 bytes or
something in that range.

Each block volume in RBD is represented by an _image_ of a given size.
For storage, each image is split into fixed-size objects.  The default
size of these objects is 4MiB (2^22 bytes).  For example, a 2TiB (2^41
bytes) image would map to 524288 (2^19) objects.  Note that these
objects are only created as needed, i.e. when written to.  This is
called _lazy allocation_ or _thin provisioning_.  The system also
supports _snapshots_, i.e. a read-only representation of all the
objects of an image at one point in time.  Once an object is in a
snapshot, it cannot be modified anymore; instead, when the image is
written to, a new copy of such an object is made and modified instead.
This is called _copy on write_.

### Accessing data volumes from an NFS server

NFS servers are VMs running under Qemu.  The NFS server implementation
that we use lives in the Linux kernel (on some other systems, NFS
servers are userspace processes).  The NFS server accesses a local
file system and exposes (exports) it via the NFS protocol.  In this
section we talk about the "local" side, not the NFS side.

Each NFS server mounts some subset of data volumes as XFS file systems
backed by block devices.  The corresponding `/etc/fstab` entries look
like

```
[...]
LABEL=data /mnt/data xfs noatime 0 0
LABEL=201 /mnt/201 xfs noatime 0 0
LABEL=202 /mnt/202 xfs noatime 0 0
[...]
```

The underlying block devices are "virtio-blk" devices such as
`/dev/vdb`, `/dev/vdc` etc.  The `virtio-blk` driver in the NFS
server's kernel talks (via a virto protocol) to an emulated device
provided by Qemu.  Inside Qemu, this device is mapped to Ceph
operations on a RBD "image" (corresponding to the respective data
volume) via the `librbd` library.  Because of how `librbd` is
implemented, for each device (aka data volume/RBD image), there can
and will be many threads inside the Qemu process.  Each of these
threads holds an open TCP connection to the (primary) OSD that's
responsible for some parts of the volume.

While the Qemu process has many threads per volume to talk to the
underlying RBD image, in the current system it contains [only one
thread per
volume](https://www.spinics.net/lists/ceph-users/msg41611.html) to
actually handle requests from the VM.

A nice description of the general process of serving block I/O
requests from a "guest" (such as an NFS server) in KVM can be found on
[KVM Architecture Overview—2015
Edition](https://vmsplice.net/~stefan/qemu-kvm-architecture-2015.pdf)
by [Stefan Hajnoczi](https://vmsplice.net/), pages 17 and following.
Note that RBD/Ceph is missing from this picture—that's another complex
affair that would replace the host "(Physical) Disk" in the diagrams.

## Multithreading

TODO
