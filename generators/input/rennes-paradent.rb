site :rennes do |site_uid|
  
  cluster :paradent do |cluster_uid|
    model "Carry System"
    created_at Time.parse("2009-02-01").httpdate
    
    64.times do |i|
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
          :version => "L5420",
          :clock_speed => 2.5.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 32.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "5.0",
          :version => nil,
          :kernel => "2.6.26"
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 160.GB,
          :driver => "ata_piix"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :management => false,
          :mountable => true,
          :mounted => true,
          :device => "eth0",
          :driver => "e1000e",
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch => "c6509-grid",
          :switch_port => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac => lookup('rennes-paradent', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => false,
          :device => "eth1",
          :driver => "e1000e"
        }]        
      end
    end
  end
  
end