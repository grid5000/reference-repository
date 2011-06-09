require 'net/ssh'
site :orsay do |site_uid|
  ssh = Net::SSH.start("frontend.#{site_uid}.grid5000.fr","g5kadmin")
  
  cluster :netgdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    1.upto(30) do |i|
      node "#{cluster_uid}-#{i}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "246",
          :clock_speed => 2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "debian-x64-5-prod",
          :release => "5.1.2",
          :version => "5",
          :kernel   => "2.6.26"
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :device => 'bmc',
            :rate => (eval lookup('orsay-network', "switch-bmc-netgdx", 'rate')),
            :mac => lookup('orsay-netgdx', "#{node_uid}", 'mac_bmc'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => true,
            :mountable => false,
            :mounted => false,
            :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-bmc.#{site_uid}.grid5000.fr"),
            :switch => (lookup('orsay-network', "switch-bmc-netgdx", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-bmc-netgdx", 'ip'),
            :switch_mac => lookup('orsay-network', "switch-bmc-netgdx", 'mac'),
            :switch_console => (lookup('orsay-network', "switch-rsa-netgdx", 'name')+".#{site_uid}.grid5000.fr"),
            :switch_console_ip => lookup('orsay-network', "switch-rsa-netgdx", 'ip'),
            :switch_console_mac => lookup('orsay-network', "switch-rsa-netgdx", 'mac'),
          },{
            :interface => 'Ethernet',
            :device => 'eth0',
            :rate => (eval lookup('orsay-network', "switch-gw", 'rate')),
            :mac => lookup('orsay-netgdx', "#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => (lookup('orsay-network', "switch-gw", 'name-prod')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-gw", 'ip-prod'),
            :switch_mac => lookup('orsay-network', "switch-gw", 'mac-prod'),
          },{
            :interface => 'Ethernet',
            :device => 'eth1',
            :rate => (eval lookup('orsay-network', "switch-gw", 'rate')),
            :mac => lookup('orsay-netgdx', "#{node_uid}", 'mac_eth1'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true, 
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :switch => (lookup('orsay-network', "switch-gw", 'name-prod')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-gw", 'ip-prod'),
            :switch_mac => lookup('orsay-network', "switch-gw", 'mac-prod'),
          },{
            :interface => 'Ethernet',
            :device => 'eth2',
            :rate => (eval lookup('orsay-network', "switch-gw", 'rate')),
            :mac => lookup('orsay-netgdx', "#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5703',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}-eth2.#{site_uid}.grid5000.fr",
            :ip => dns_lookup_through_ssh(ssh,"#{node_uid}-eth2.#{site_uid}.grid5000.fr"),
            :switch => (lookup('orsay-network', "switch-gw", 'name-prod')+".#{site_uid}.grid5000.fr"),
            :switch_ip => lookup('orsay-network', "switch-gw", 'ip-prod'),
            :switch_mac => lookup('orsay-network', "switch-gw", 'mac-prod'),
          }]  
      end      
    end
  end # cluster net-gdx

  ssh.close
end
