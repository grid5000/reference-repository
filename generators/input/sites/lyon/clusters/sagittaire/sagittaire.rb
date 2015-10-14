site :lyon do |site_uid|

  cluster :sagittaire do |cluster_uid|
    model "Sun Fire V20z"
    created_at Time.parse("2006-07-01 12:00 GMT").httpdate
    kavlan true
    production true

    79.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 3929000000,
        :node_flops => 7440000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup(node_uid, node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup(node_uid, node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup(node_uid, node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup(node_uid, node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup(node_uid, node_uid, 'processor', 'vendor'),
          :model              => lookup(node_uid, node_uid, 'processor', 'model'),
          :version            => lookup(node_uid, node_uid, 'processor', 'version'),
          :clock_speed        => lookup(node_uid, node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup(node_uid, node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup(node_uid, node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup(node_uid, node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup(node_uid, node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup(node_uid, node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup(node_uid, node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup(node_uid, node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup(node_uid, node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => "debian",
          :release  => "Wheezy",
          :version  => "7",
          :kernel   => "3.2.0-4-amd64"
        })

        if (i<69) then
          storage_devices [{
            :interface  => 'SCSI',
            :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
            :driver     => "mptspi",
            :device     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'device'),
            :model      => lookup(node_uid, node_uid, 'block_devices', 'sda', 'model'),
            :rev        => lookup(node_uid, node_uid, 'block_devices', 'sda', 'rev'),
            :storage    => 'HDD'
          }]
        else
          storage_devices [{
            :interface  => 'SCSI',
            :size       => lookup(node_uid, node_uid, 'block_devices', 'sda', 'size'),
            :driver     => "mptspi",
            :device     => lookup(node_uid, node_uid, 'block_devices', 'sda', 'device'),
            :model      => lookup(node_uid, node_uid, 'block_devices', 'sda', 'model'),
            :rev        => lookup(node_uid, node_uid, 'block_devices', 'sda', 'rev'),
            :storage    => 'HDD'
          },
          {
            :interface  => 'SCSI',
            :size       => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'size'),
            :driver     => "mptspi",
            :device     => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'device'),
            :model      => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'model'),
            :rev        => lookup(node_uid, node_uid, 'block_devices', 'sdb', 'rev'),
            :storage    => 'HDD'
          }]
        end
        network_adapters [{
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => false,
          :device           => "eth0",
          :vendor           => 'Broadcom',
          :model            => 'BCM5704',
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'ip'),
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => true,
          :device           => "eth1",
          :vendor           => 'Broadcom',
          :model            => 'BCM5704',
          :driver           => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'ip6'),
          :switch           => net_switch_lookup('lyon', 'sagittaire', node_uid, 'eth1'),
          :switch_port      => net_port_lookup('lyon', 'sagittaire', node_uid, 'eth1'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'eth1', 'mac')
        },
        {
          :interface        => 'Ethernet',
          :rate             => 1.G,
          :enabled          => true,
          :management       => true,
          :mountable        => false,
          :mounted          => false,
          :device           => "bmc",
          :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
          :ip               => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac              => lookup(node_uid, node_uid, 'network_interfaces', 'bmc', 'mac'),
          :driver           => "bnx2"
        }]

        chassis({
          :serial       => lookup(node_uid, node_uid, 'chassis', 'serial_number'),
          :name         => lookup(node_uid, node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup(node_uid, node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup(node_uid, node_uid, 'bios', 'version'),
          :vendor       => lookup(node_uid, node_uid, 'bios', 'vendor'),
          :release_date => lookup(node_uid, node_uid, 'bios', 'release_date')
        })

        gpu({
          :gpu  => false
        })

        monitoring({
          :wattmeter  => true
        })

        sensors({
          :power => {
            :available => true,
            :per_outlets => true,
            :via => {
              :api => { :metric => 'pdu' },
              :www => { :url => 'http://wattmetre.lyon.grid5000.fr/GetWatts-json.php' },
            }
          }
        })
      end
    end
  end # cluster sagittaire
end
