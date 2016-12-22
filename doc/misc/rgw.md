# Requirements

- write and read are about equal. Mabe a tiny bit more read.

In kibana we see, that we get peaks of about 25k reads/ writes per 30 Minutes -> about 15 reads/s & 15 writes/s.

With multipart file upload that'll be a bit more. Also short peaks might be significantly higher -> we should at least size for 20-25 op/s in and 20-25 ops out.


# Tests

run tests on ubuntu@test.tldrive:cosbench/cos
   start cosbench: ./start-all.sh
   
create tunnel: ssh -L18088:localhost:18088 -L19088:localhost:19088 test.tldrive

open in browser: http://127.0.0.1:19088/controller/

submit job with: ./cli.sh submit conf/<job>.xml



Test results:

test    num_workers resTime reads/s writes/s    size        num_objects     num_buckets
rgw_1_1 50           2.2       11      11              4KB         10k - 20k       1
rgw_1_2 50           3.6       7        7            4.5MB       10k - 20k       1

rgw_2_1 50          2.2        11       11             4KB         10k - 20k       100
rgw_2_2 50                                      4KB         100k - 110k     100

rgw_3_1 50                                      4KB         100k - 110k     1
rgw_3_2 50          2.2            11      11          4KB         1M - 1.01M       1

rgw_4_1 500         20-30           6      6.5           4KB         10k - 20k       1       lot's failed

turn on versioning.


---------

find id of bucket with 
    radosgw-admin bucket stats | less

example: default.49650719.424

count objects in bucket:
    rados -p .rgw.buckets.index listomapkeys .dir.<bucket_id> | wc -l
    
example:
    rados -p .rgw.buckets.index listomapkeys .dir.default.49650719.424 | wc -l













-----
References:

https://arvimal.wordpress.com/2016/06/30/sharding-the-ceph-rados-gateway-bucket-index/
http://ceph.com/planet/radosgw-big-index/
http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-November/014437.html

