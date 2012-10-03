site :grenoble do |site_uid|

  cluster :edel do |cluster_uid|
    model "Bull bullx B500 compute blades"
    created_at Time.parse("2008-10-03").httpdate

    72.times do |i|
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
          :clock_speed => 2.27.G,
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
          :size => 60.GB,
          :driver => "ahci",
          :model => lookup('edel', node_uid, 'block_devices', 'sda', 'model')
        }]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 40.G,
          :enabled => true,
          :device => "ib0",
          :mounted => true,
          :mountable => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s (rev a0)",
          :driver => "mlx4_core",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => lookup('edel', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid => lookup('edel', node_uid, 'network_interfaces', 'ib0', 'guid')
        },
        {
          :interface => 'InfiniBand',
          :rate => 40.G,
          :enabled => false,
          :device => "ib1",
          :mounted => false,
          :mountable => false,
          :management => false,
          :vendor => 'Mellanox',
          :version => "MT26428 ConnectX IB QDR, PCIe 2.0 5.0GT/s (rev a0)",
          :driver => "mlx4_core",
          :guid => lookup('edel', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :device => "eth0",
          :mounted => true,
          :mountable => true,
          :bridged => true,   
          :management => false,
          :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
          :ip => lookup('edel', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :mac => lookup('edel', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor => "Intel",
          :version => "82576 Gigabit Network Connection",
          :driver => "igb",
          :switch => lookup('edel', node_uid, 'network_interfaces', 'eth0', 'switch_name'),
          :switch_port => lookup('edel', node_uid, 'network_interfaces', 'eth0', 'switch_port')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => false,
          :mounted => false,
          :mountable => false,
          :management => false,
          :vendor => "Intel",
          :version => "82576 Gigabit Network Connection",
          :mac => lookup('edel', node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface => 'Ethernet',
          :rate => 100.M,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('edel', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('edel', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor => "Unknown",
          :version => "1.7"
        }]
        bios({
          :version      => lookup('edel', node_uid, 'bios', 'version'),
          :vendor       => lookup('edel', node_uid, 'bios', 'vendor'),
          :release_date => lookup('edel', node_uid, 'bios', 'release_date')
        })
        chassis({
          :serial       => lookup('edel', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('edel', node_uid, 'chassis', 'product_name')
        })
        monitoring({
          :wattmeter  => true
        })
      end
    end
  end

end
