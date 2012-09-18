site :grenoble do |site_uid|

 cluster :adonis do |cluster_uid|
    created_at Time.parse("2010-09-02").httpdate
    10.times do |i|
      model "Bull R422-E2 dual mobo + Tesla S1070"
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
          :version => "E5520",
          :clock_speed => 2.26.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 24.GiB, # bytes
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
          :size => 250.GB,
          :driver => "ahci",
          :model => lookup('adonis', node_uid, 'block_devices', 'sda', 'model')
        }]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 40.G,
          :device => "ib0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s",
          :driver => "mlx4_core",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid => lookup('adonis', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :bridged => true,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :mac => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :driver => "igb",
          :switch => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port => lookup('adonis', node_uid, 'network_interfaces', 'eth0', 'switch_port')

        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :management => false,
          :vendor => 'Intel',
          :version => "Device 10c9 (rev 01)",
          :mac => lookup('adonis', node_uid, 'network_interfaces', 'eth1', 'mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('adonis', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('adonis', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor => 'Super Micro Computer Inc.',
          :version => "1.15"
        }]
        bios({
          :version      => lookup('adonis', node_uid, 'bios', 'version'),
          :vendor       => lookup('adonis', node_uid, 'bios', 'vendor'),
          :release_date => lookup('adonis', node_uid, 'bios', 'release_date')
        })
        chassis({
          :serial       => lookup('adonis', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('adonis', node_uid, 'chassis', 'product_name')
       })
        graphics({
          :gpu         =>  lookup('adonis', node_uid , 'graphics', 'gpu'),
          :gpu_count   =>  lookup('adonis', node_uid, 'graphics', 'gpu_count'),
          :gpu_model   =>  lookup('adonis', node_uid, 'graphics', 'gpu_model'),
           })
      end
    end
  end

end
