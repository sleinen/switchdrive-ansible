
DOMAIN     = 'drive.switch.ch'
SUB_DOMAIN = 'ocdev'

VIRTUAL_BOX_GROUP = "/ocdev"

# networks: we don't need ipv6 here. If the IP specified here does not match the one 
# from puppet it will be provisioned as secondary IP on the interface. -> see router eth1
mgmt = '10.254.0'

# forwarded ports: 'guest_port' => 'host_port'
NODES = {
  'ocapp'  => { :ram => 2048, :cpu => 2, :nic => ["#{mgmt}.2/24"], :forwarded_ports => {"8080" => "8080", "80" => "8081"}},
}

DISKS = {
  'test0003'   => [
    {:port => 1, :size => 1024*1024},
    {:port => 2, :size => 1024*1024},
                  ],
}
