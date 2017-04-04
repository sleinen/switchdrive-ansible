# Galera Cluster Setup @ SWITCHdrive

Wir hatten Oli Sennhauser von http://fromdual.com/ im Haus. Ich hab seine Kommentare direkt eingearbeitet (OLI: tags)
Ich hab keine Erlaubnis von Herrn Sennhauser eingeholt, dass seine Kommentare veröffentlicht werden dürfen, daher bitte ich euch ihn nicht zu zitieren.

## Hardware

- 3 virtual machines (Openstack with KVM und Ceph / local SSDs)
  - 46 vCPU
  - 245 GB RAM
  - 1.5 TB SSDs


- Die VMs laufen als einzige VM auf einem dedizierten Hypervisor der knapp grösser ist: 256 GB RAM, 24 Cores (mit Hyperthreading).
- Dies heisst für uns, das 50% CPU Last in der VM effektiv eher 70-80 % CPU last bedeuten.

- OLI:
  - CPU: Die Virtualisierung könnte ein Problem sein. Er sah mit VMware Einbussen von 25%.
  - VMWare hat Probleme mit CPU überbuchung. KVM kennt er nicht. Da wir jedoch dedizierte Hypervisors haben, überbuchen wir auch nicht.
  - RAM: ist nur zu 20% genutzt, könnte also massiv kleiner sein. Macht bei uns jedoch nicht Sinn, da wir das RAM des dedizierten Hypervisors ohnehin nicht für irgendwas anderes nutzen könnten.
  - SWAP: sollte nie Grösse 0 haben, wegen dem OOM Killer. (Bei unserem massiv zu grossen RAM aber kein Problem)


- Übers Ganze gesehn, war die Virtualisierung Oli's grösste Kritik an unserem Galera-Cluster. Wir haben die Virtualisierung jedoch belassen, da wir in unserm Openstack cluster
  - keinen bare-metal driver für Nova in Betrieb haben
  - Neutron nutzen und extern angebundene bare-metal Server daher eine zu grosse Netzwerklatency hätten.
  - unsere Erfahrung mit KVM sehr gut ist und wir das auch unseren Kunden anbieten.

## Software

- Ubuntu 16.04 mit XFS als Filesystem für Datenpartition.
- Mariadb: 10.1.16. Wir nutzen offizielles Dockerimage (unverändert)
- maxscale: 1.4.3
- Monitoring: prometheus & grafana mit percona plugin.

- OLI: er ist kein Freund von Virtualisierung und auch nicht von Docker.
- Bei uns läuft Docker jedoch problemlos. Die DB Daten halten wir allerdings nicht in einem data volume container sondern ausserhalb von Docker!

- OLI:
  - Mariadb hat mehr Stabilitätprobleme als MYSQL. Sie sind mehr "Assembler" welche ein Stück von hier und ein Stück von da integrieren. Das machen Sie aber nicht immer sehr sorgfältig. (Es sei aber eher besser geworden.)
  - Percona ist scheinbar auf dem sterbenden Ast. Hatten mal viel Know-How, aber ist viel von abgewandert.
  - Mariadb und MySQL driften immer mehr auseinander
  - Seine Empfehlung:  Für den Moment kein Handlungsbedarf. Mal bei Mariadb bleiben und sehn wie es sich entwickelt.

## Deployment

- Mit Ansible.
- Playbooks und Roles sind verfügbar auf Github: https://github.com/switch-ch/switchdrive-ansible.
- Interessant ist hier die Role mariadb_base: https://github.com/switch-ch/switchdrive-ansible/tree/master/roles/mariadb_base

## Setup

- Wir haben einen 3 Node Galera cluster im selben VLan. Wir hatten mit OLI diskutiert wie wir einen asynchronen Backup in einem zweiten Rechenzentrum haben könnten. Das liesse sich machen indem man einen der 3 Nodes als Master eines master/slave Pärchens konfiguriert mit dem Slave im zweiten Rechenzentrum. Der Slave könnte dann wieder Teil eines Galera clusters im zweiten Rechenzentrum sein. Das hat aber den Nachteil, dass man das Backup verliert falls einer der beiden master/slave Server ausfällt. Alternativ könnte man zwei master/slave Pärchen ohne Galera im zweiten Rechenzentrum konfigurieren und dort dann Galera erst einschalten bevor man einen Fail-over macht.
https://severalnines.com/blog/deploy-asynchronous-replication-slave-mariadb-galera-cluster-gtid-clustercontrol


- Wir haben je einen Maxscale daemon auf jeden application server gepackt. Php spricht mit dem lokalen Maxscale. Wir mussten dies so machen, da Maxscale so viel CPU frisst, dass wir unmöglich einen zentralen Server hätten hinstellen können. Maxscale frisst oft ähnlich viel CPU wie php. Daher wäre es uns wichtig diesen read/write splitter in Rente schicken zu können. Zudem ist Maxscale schlecht im load-balancen, die read Last ist oft sehr schlecht auf die Server verteilt. haproxy würde dies wohl besser machen, kann aber keinen read/write split.

- OLI: hat sich die Maxscale konfig angesehn und keine Optimierungsmöglichkeit gesehn. Er sagte aber, er kenne sich nicht besonders aus mit Maxscale. Wies uns aber auf einen Maxscale Fork hin, welchen er aber auch nicht genauer kenne: https://github.com/airbnb/maxscale. (Scheint inzwischen bereits wieder ein totes Projekt zu sein.)

## Config

Template is at: https://github.com/switch-ch/switchdrive-ansible/blob/master/roles/mariadb_base/templates/drive.switch.ch/mariadb.cnf


    [mysqld]

    # --- owncloud stuff ---

    ## owncloud uses collation utf8_bin, It is set at table level -> no need
    ## to change default;  collection=utf8_bin will also set character set to utf8
    #collation-server = utf8_bin
    #init-connect='SET NAMES utf8'

    # --- required by galera ---

    default_storage_engine=InnoDB
    innodb_autoinc_lock_mode=2
    innodb_flush_log_at_trx_commit=0
    binlog_format=ROW

    # this is required for consistent log files with galera that can be used for master/slave replication.
    log_slave_updates=ON

    # query cache is ok in a Galera context for mariadb > 10.1.2
    # nextcloud developers recommend activating the cache (not convinced that they know what they're doing)
    #query_cache_type=1
    #query_cache_size=1024M
    #query_cache_limit=2M
    # I tried turning it on -> it was a desaster :-(

    # http://aadant.com/blog/wp-content/uploads/2013/09/50-Tips-for-Boosting-MySQL-Performance-CON2655.pdf recommends turning it off
    query_cache_type=0
    query_cache_size=0
OLI: most of the time cache is not working well. -> rather cache in application if that is possible.

    # --- wsrep ---

    wsrep_on=True
    wsrep_provider=/usr/lib/galera/libgalera_smm.so
    wsrep_provider_options="gcache.size=1024M"
    wsrep_cluster_name=SWITCHdrive
    wsrep_cluster_address=gcomm://10.0.23.31,10.0.23.32
    wsrep_node_address=10.0.23.31
    wsrep_sst_method=rsync

    # comment out if all tables have primary key.
    #wsrep_certify_nonPK=1

    # default values (OLI: defaults are ok here -> comment out)
    #wsrep_max_ws_rows=131072
    #wsrep_max_ws_size=1073741824
    #wsrep_retry_autocommit=1
    #wsrep_auto_increment_control=ON

    ## twice the number of CPU or even more (4-8 times num CPU)
    wsrep_slave_threads=90

    ## Critical reads:
    wsrep_sync_wait=1

    # --- debug / log ---
    #wsrep_debug = 1
    wsrep_log_conflicts=ON


    # --- innodb --- (https://mariadb.com/kb/en/mariadb/xtradbinnodb-server-system-variables/)
    innodb_file_per_table=1
    # ON: When an IST occurs, want there to be no torn pages? (With FusionIO or other drives that guarantee atomicity, OFF is better.)
    innodb_doublewrite=ON

    # optimization for SSDs (default is 512)
    innodb_log_block_size=4096
OLI: he raised his eyebrow here: 4096 is not default and might lead to problems. But he was not really sure.

    # 60-80 % of RAM (in bytes)
    innodb_buffer_pool_size=170G
    # innodb_buffer_pool_size / 1GB or less
    innodb_buffer_pool_instances=64
    # default: 200
    innodb_io_capacity=1000
    # (default: 4
    innodb_read_io_threads=8
    # default: 4
    innodb_write_io_threads=8
    # default: 1
    innodb_purge_threads=4
OLI: we had larger values for thread settings. Oli recommended the lower values as set above.

    # increase concurrency: (default =1)
    innodb_sync_array_size=8
    # limit number of threads. (2x CPU + num disks)
    innodb_thread_concurrency=92

    # https://www.percona.com/blog/2016/05/31/what-is-a-big-innodb_log_file_size/
    innodb_log_file_size=500MB

    # --- threading ---
    #thread_handling=pool-of-threads
    #thread_pool_max_threads=10000
    #thread_pool_size=44
    # pool-of-threads or thread cache not both!
    # thread_cache_size should be equal to max_connections
    thread_cache_size=1024
OLI: we had `thread_handling=pool-of-threads`: Oli said that that would only make sense if > 1000 client connections per second per server. That is not the case for us. "thread_cache_size=1024" is adapted to our load. -> look at monitoring over past few months and see what the highest 'normal not exceptional' number of connections was.


    # --- misc ---
    #
    max_connections=1024
    max_connect_errors=100

    # Owncloud is writing avatar into db :-( (starting with OC 9.0 uncomment this)
    # this was input from sciebo
    #max_allowed_packet=128M

    tmp_table_size=32M
    max_heap_table_size=32M
    # https://mariadb.com/kb/en/mariadb/optimizing-table_open_cache/
    table_open_cache=2000

    # http://dimitrik.free.fr/blog/archives/2012/07/mysql-performance-readonly-adventure-in-mysql-56.html
    innodb_spin_wait_delay=94
OLI: he thought that his would not be necessary.

    # don't check dns
    skip-name-resolve

    # --- logging ---
    #log_syslog=1
    #server_audit_output_type=SYSLOG
    innodb_print_all_deadlocks=ON
    log_warnings = 2

    slow-query-log = 1
    slow-query-log-file = /var/lib/mysql/mysql-slow.log
    log-slow-verbosity=query_plan,explain
    # long_query_time is in seconds
    long_query_time = 0.5


    # --- percona grafana plugin ---
    # comment out the following lines when initializing new DB. It'll fail otherwise.
    performance_schema=on
    userstat=1
    query_response_time_stats=1

## Sciebo Config

Wir hatten Oli auch die Konfig von Sciebo vorgelegt und beurteilen lassen. Hier seine Kommentare:

- `transaction-isolation=READ-COMMITTED`
Hat ihm nicht gefallen. Weiss nicht mehr warum.

- `innodb_log_file_size = 4G`
Viel zu gross. 500GB ist besser
- `wsrep_retry_autocommit=32`
Hammer Methode -> lieber Problem fixen. Holger meinte das stamme aus Zeit bevor sie read/write split hatten.



## Upgrade

- according to Oli upgrading server by server without downtime should work.
- we never tested that tough.

## Useful commands

- Analyse des slow-query-logs: `mysqldumpslow -s t mysql-slow.log  > log.profile`
- `show processlist;`: zeigt was aktuell auf db server läuft. Zuerst pager configurieren mit: `pager grep -v Sleep`
- `show create table owncloud.oc_filecache\G`
- `select table_name, data_length, index_length from information_schema.tables where table_schema = 'owncloud';`
- `select table_schema, engine, count(*) from information_schema.tables group by table_schema, engine;`

- `show global status;`
- `status`

## Abschliessender Kommentar

Oli meinte all die Configänderungen die er vorschlug würden in unserem Fall nicht mehr sonderlich viel bringen. Um mehr aus der DB herauszuholen müsste man den php code analysieren und optimieren. Er kenne zwar Owncloud nicht, aber aus Erfahrung wisse er, dass man im Code meistens noch sehr viel optimieren kann. Inzwischen wissen wir, dass er damit völlig richtig lag.
Vielleicht würde es sich lohnen das DB-Schema und den Code mal mit einem DB Experten zu besprechen.
