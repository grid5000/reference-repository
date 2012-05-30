site :sophia do |site_uid|

  cluster :helios do |cluster_uid|
    model "Sun Fire X4100"
    created_at Time.parse("2006-06-02").httpdate

    56.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2,
          :smt_size => 4,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "275",
          :clock_speed => 2.2.G,
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
          :interface => 'SAS',
          :size => 73.GB,
          :driver => "mptsas",
          :raid => "0"
        },
        {
          :interface => 'SAS',
          :size => 73.GB,
          :driver => "mptsas",
          :raid => "0"
        },
        {
          :interface  => 'SAS',
          :size => lookup('helios', node_uid, 'block_devices', 'sda', 'size'),
          :driver => "mptsas",
          :device => "sda",
          :model  => lookup('helios', node_uid, 'block_devices', 'sda', 'model'),
          :rev  => lookup('helios', node_uid, 'block_devices', 'sda', 'rev')
        }]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('helios', node_uid, 'network_interfaces','eth0', 'mac'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => true,
            :management => false,
            :mountable => true,
            :bridged => true,
            :driver => "e1000",
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :switch => lookup('helios', node_uid, 'network_interfaces','eth0', 'switch_name'),
            :switch_port => lookup('helios', node_uid, 'network_interfaces','eth0', 'switch_port'),
            :ip => lookup('helios', node_uid, 'network_interfaces','eth0', 'ip')
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('helios', node_uid, 'network_interfaces','eth1', 'mac'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth1'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('helios', node_uid, 'network_interfaces','eth2', 'mac'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth2'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('helios', node_uid, 'network_interfaces','eth3', 'mac'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth3'
          },{
            :interface => 'Myrinet',
            :rate => 2.G,
            :mac => nil,
            :vendor => 'Myricom',
            :version => 'M3F-PCIXF-2',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true,
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => lookup('helios', node_uid, 'network_interfaces','myri0', 'ip'),
            :switch => "edgeiron48gs"
          },{
            :interface => 'Ethernet',
            :rate => 100.M,
            :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => lookup('helios', node_uid, 'network_interfaces','bmc', 'ip'),
            :mac => lookup('helios', node_uid, 'network_interfaces','bmc', 'mac'),
            :enabled  => true,
            :mounted => false,
            :mountable => false,
            :management => true,
            :device => "bmc"
          }]
          bios({
            :version => lookup('helios', node_uid, 'network_interfaces','version'),
            :vendor => lookup('helios', node_uid, 'network_interfaces','vendor'),
            :release_date => lookup('helios', node_uid, 'network_interfaces','release_date'),
          })
          chassis({
            :serial => lookup('helios', node_uid, 'chassis','serial_number'),
            :name => lookup('helios', node_uid, 'chassis','product_name'),
          })
      end
    end
  end

end
