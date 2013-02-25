site :lille do |site_uid|

  cluster :chimint do |cluster_uid|
    model "Dell PowerEdge R410"
    created_at Time.parse("2011-03-25").httpdate
    kavlan true
    20.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5620",
          :clock_speed => 2.4.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 12.MiB
        })
        main_memory({
          :ram_size => 16.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [
          {:interface => 'SATA',
            :size => 300.GB,
            :driver => "megaraid_sas",
          :raid => "0"}
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('chimint', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor => 'Broadcom',
          :version => 'NetXtreme II BCM5716',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'bnx2',
          :mounted => true,
          :bridged => true,
          :device => 'eth0',
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('chimint', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch => 'gw-lille'
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('chimint', node_uid, 'network_interfaces', 'eth1', 'mac'),
          :vendor => 'Broadcom',
          :version => 'NetXtreme II BCM5716',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'bnx2',
          :mounted => false,
          :device => 'eth1',
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('chimint', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :switch => 'gw-lille',
          :switch_port => lookup('chimint', node_uid, 'network_interfaces', 'eth1', 'switch_port')
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('chimint', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor => 'Dell',
          :version => '1.54',
          :enabled => true,
          :management => true,
          :mountable => false,
          :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :ip => lookup('chimint', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :switch => 'gw-lille'
        }]
          gpu({
          :gpu  => false
           })

        monitoring({
          :wattmeter  => false
        })
      end
    end
  end # cluster chimint

end
