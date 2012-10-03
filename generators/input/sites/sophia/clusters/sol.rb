site :sophia do |site_uid|

  cluster :sol do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-02-23").httpdate
    50.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "amd-v"})
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "2218",
          :clock_speed => 2.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "Squeeze",
          :version => "6.0",
          :kernel => "2.6.32"
        })
        storage_devices [{
          :interface => 'SATA',
          :size =>  250.GB,
          :device => "sda",
          :model  => lookup('sol', node_uid, 'block_devices', 'sda', 'model'),
          :driver => "sata_nv"
        }]
        network_adapters [{ 
             :interface => 'Myrinet',
             :rate => 10.G,
             :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
             :ip => lookup('sol', node_uid, 'network_interfaces','myri0', 'ip'),
             :mac => nil,
             :mac => lookup('sol', node_uid, 'network_interfaces','myri0', 'mac'),
             :enabled => true,
             :mounted => true,
             :mountable => true,
             :management => false,
             :vendor => 'Myricom',
             :version => "M3F-PCIXF-2",
             :driver => "mx",
             :switch => "edgeiron48gs",
             :device => 'myri0',
             },
            {
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sol', node_uid, 'network_interfaces', 'eth0', 'mac'),
            :ip => lookup('sol', node_uid, 'network_interfaces','eth0', 'ip'),
            :vendor => 'nVidia',
            :version => 'MCP55 Pro',
            :enabled => true,
            :management => false,
            :mountable => true,
            :bridged => true,
            :driver => 'forcedeth',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :switch => lookup('sol', node_uid, 'network_interfaces','eth0', 'switch_name'),
            :switch_port => lookup('sol', node_uid, 'network_interfaces','eth0', 'switch_port')
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sol', node_uid, 'network_interfaces', 'eth1', 'mac'),
            :vendor => 'nVidia',
            :version => 'MCP55 Pro',
            :enabled => false,
            :driver => 'forcedeth',
            :device => 'eth1'
          },
         # ,{
         #   :interface => 'Ethernet',
         #   :rate => 1.G,
         #   :mac => nil,
         #   :vendor => 'Broadcom',
         #   :version => 'BCM5715c',
         #   :enabled => false,
         #   :driver => 'tg3'
         # },{
         #   :interface => 'Ethernet',
         #   :rate => 1.G,
         #   :mac => nil,
         #   :vendor => 'Broadcom',
         #   :version => 'BCM5715c',
         #   :enabled => false,
         #   :driver => 'tg3
         # }
          
          {
            :interface => 'Ethernet',
            :rate => 100.M,
            :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => lookup('sol', node_uid, 'network_interfaces','bmc', 'ip'),
            :mac => lookup('sol', node_uid, 'network_interfaces','bmc', 'mac'),
            :enabled  => true,
            :mounted => false,
            :mountable => false,
            :management => true,
            :device => "bmc"
          }]
          bios({
            :version => lookup('sol', node_uid, 'network_interfaces','version'),
             :vendor => lookup('sol', node_uid, 'network_interfaces','vendor'),
            :release_date => lookup('sol', node_uid, 'network_interfaces','release_date')
          })
          chassis({
            :serial => lookup('sol', node_uid, 'chassis','serial_number'),
            :name => lookup('sol', node_uid, 'chassis','product_name')
          })
          monitoring({
            :wattmeter  => false
          })
      end
    end
  end

end
