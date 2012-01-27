site :lille do |site_uid|

  cluster :chinqchint do |cluster_uid|
    model "Altix Xe 310"
    created_at nil
    46.times do |i|
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
          :version => "E5440 QC",
          :clock_speed => 2.83.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MiB
        })
        main_memory({
          :ram_size => 8.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [
          {:interface => 'SATA II', :size => 250.GB, :driver => "ahci"}
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'eth0', 'mac'),
          :vendor => 'Intel',
          :version => '80003ES2LAN',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'e1000e',
          :mounted => true,
          :device => 'eth0',
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'eth0', 'ip'),
          :switch => 'gw'
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'eth1', 'mac'),
          :vendor => 'Intel',
          :version => '80003ES2LAN',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'e1000e',
          :mounted => true,
          :device => 'eth1',
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'eth1', 'ip'),
          :switch => 'gw',
          :switch_port => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'eth1', 'switch_port'),
        },{
          :interface => 'Ethernet',
          :rate => 1.G,
          :mac => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'bmc', 'mac'),
          :vendor => 'Peppercon',
          :version => '1.46',
          :enabled => true,
          :management => true,
          :mountable => false,
          :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'bmc', 'ip'),
          :switch => 'gw'
        },{
          :interface => 'Myrinet',
          :rate => 10.G,
          :mac => nil,
          :vendor => 'Myricom',
          :version => '10G-PCIE-8A-C',
          :enabled => true,
          :management => false,
          :mountable => true,
          :driver => 'mx',
          :mounted => true,
          :device => 'myri0',
          :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
          :ip => lookup('lille-chinqchint',"#{node_uid}",'network_interfaces', 'myri0', 'ip'),
          :switch => nil
        }]
      end
    end
  end

end
