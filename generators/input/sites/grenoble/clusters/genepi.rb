site :grenoble do |site_uid|

  cluster :genepi do |cluster_uid|
    model "Bull R422-E1"
    created_at Time.parse("2008-10-01").httpdate

    34.times do |i|
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
          :version => "E5420 QC",
          :clock_speed => 2.5.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 8.GiB, # bytes
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
          :size => 160.GB,
          :model => lookup('genepi', node_uid, 'block_devices', 'sda', 'model'),
          :vendor => lookup('genepi', node_uid, 'block_devices', 'sda', 'vendor'),
          :driver => "ata_piix"
        }]
        network_adapters [{
          :interface => 'InfiniBand',
          :rate => 20.G,
          :device => "ib0",
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :management => false,
          :vendor => 'Mellanox',
          :version => "InfiniHost MHGH29-XTC",
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
          :ip => lookup('genepi', node_uid, 'network_interfaces', 'ib0', 'ip'),
          :guid => lookup('genepi', node_uid, 'network_interfaces', 'ib0', 'guid'),
          :driver => "mlx4_core"
        },
        {
          :interface => 'InfiniBand',
          :rate => 10.G,
          :device => "ib1",
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :management => false,
          :vendor => 'Mellanox',
          :version => "InfiniHost MHGH29-XTC",
          :driver => "mlx4_core",
          :guid => lookup('genepi', node_uid, 'network_interfaces', 'ib1', 'guid')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth0",
          :enabled => false,
          :management => false,
          :mac => lookup('genepi', node_uid, 'network_interfaces', 'eth0', 'mac'),
          :vendor => "Intel",
          :version => "Intel 80003ES2LAN Gigabit Ethernet Controller (Copper) (rev 01)"
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :device => "eth1",
          :enabled => true,
          :mountable => true,
          :mounted => true,
          :bridged => true,
          :management => false,
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => lookup('genepi', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :mac => lookup('genepi', node_uid, 'network_interfaces', 'eth1', 'mac'),
          :vendor => "Intel",
          :version => "Intel 80003ES2LAN Gigabit Ethernet Controller (Copper) (rev 01)",
          :driver => "e1000e",
          :switch => lookup('genepi', node_uid, 'network_interfaces', 'eth1', 'switch_name'),
          :switch_port => lookup('genepi', node_uid, 'network_interfaces', 'eth1', 'switch_port')
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :enabled => true,
          :mountable => false,
          :management => true,
          :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip => lookup('genepi', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac => lookup('genepi', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :vendor => "Peppercon AG (10437)",
          :version => "1.50"
        }]
        bios({
          :version      => lookup('genepi', node_uid, 'bios', 'version'),
          :vendor       => lookup('genepi', node_uid, 'bios', 'vendor'),
          :release_date => lookup('genepi', node_uid, 'bios', 'release_date')
        })
        chassis({
          :serial       => lookup('genepi', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('genepi', node_uid, 'chassis', 'product_name')
        })
      end
    end
  end

end
