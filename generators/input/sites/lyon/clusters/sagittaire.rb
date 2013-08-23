site :lyon do |site_uid|

  cluster :sagittaire do |cluster_uid|
    model "Sun Fire V20z"
    created_at Time.parse("2006-07-01 12:00 GMT").httpdate
    kavlan true

    79.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|

        performance({
        :core_flops => 3929000000,
        :node_flops => 7440000000
      })

        supported_job_types({
          :deploy       => true,
          :besteffort   => true,
          :virtual      => lookup('sagittaire_generated', node_uid, 'supported_job_types', 'virtual')
        })

        architecture({
          :smp_size       => lookup('sagittaire_generated', node_uid, 'architecture', 'smp_size'),
          :smt_size       => lookup('sagittaire_generated', node_uid, 'architecture', 'smt_size'),
          :platform_type  => lookup('sagittaire_generated', node_uid, 'architecture', 'platform_type')
        })

        processor({
          :vendor             => lookup('sagittaire_generated', node_uid, 'processor', 'vendor'),
          :model              => lookup('sagittaire_generated', node_uid, 'processor', 'model'),
          :version            => lookup('sagittaire_generated', node_uid, 'processor', 'version'),
          :clock_speed        => lookup('sagittaire_generated', node_uid, 'processor', 'clock_speed'),
          :instruction_set    => lookup('sagittaire_generated', node_uid, 'processor', 'instruction_set'),
          :other_description  => lookup('sagittaire_generated', node_uid, 'processor', 'other_description'),
          :cache_l1           => lookup('sagittaire_generated', node_uid, 'processor', 'cache_l1'),
          :cache_l1i          => lookup('sagittaire_generated', node_uid, 'processor', 'cache_l1i'),
          :cache_l1d          => lookup('sagittaire_generated', node_uid, 'processor', 'cache_l1d'),
          :cache_l2           => lookup('sagittaire_generated', node_uid, 'processor', 'cache_l2'),
          :cache_l3           => lookup('sagittaire_generated', node_uid, 'processor', 'cache_l3')
        })

        main_memory({
          :ram_size     => lookup('sagittaire_generated', node_uid, 'main_memory', 'ram_size'),
          :virtual_size => nil
        })

        operating_system({
          :name     => lookup('sagittaire_generated', node_uid, 'operating_system', 'name'),
          :release  => "Squeeze",
          :version  => lookup('sagittaire_generated', node_uid, 'operating_system', 'version'),
          :kernel   => lookup('sagittaire_generated', node_uid, 'operating_system', 'kernel')
        })

        if (i<69) then
          storage_devices [{
            :interface  => 'SCSI',
            :size       => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'size'),
            :driver     => "mptspi",
            :device     => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'device'),
            :model      => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'model'),
            :rev        => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'rev')
          }]
        else
          storage_devices [{
            :interface  => 'SCSI',
            :size       => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'size'),
            :driver     => "mptspi",
            :device     => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'device'),
            :model      => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'model'),
            :rev        => lookup('sagittaire_generated', node_uid, 'block_devices', 'sda', 'rev')
          },
          {
            :interface  => 'SCSI',
            :size       => lookup('sagittaire_generated', node_uid, 'block_devices', 'sdb', 'size'),
            :driver     => "mptspi",
            :device     => lookup('sagittaire_generated', node_uid, 'block_devices', 'sdb', 'device'),
            :model      => lookup('sagittaire_generated', node_uid, 'block_devices', 'sdb', 'model'),
            :rev        => lookup('sagittaire_generated', node_uid, 'block_devices', 'sdb', 'rev')
          }]
        end
        network_adapters [{
          :interface        => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'interface'),
          :rate             => 1.G,
          :enabled          => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'enabled'),
          :management       => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'management'),
          :mountable        => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'mountable'),
          :mounted          => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'mounted'),
          :bridged          => false,
          :device           => "eth0",
          :vendor           => 'Broadcom',
          :model            => 'BCM5704',
          :ip               => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :driver           => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'driver'),
          :mac              => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth0', 'mac')
        },
        {
          :interface        => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'interface'),
          :rate             => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'rate'),
          :enabled          => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'enabled'),
          :management       => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'management'),
          :mountable        => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'mountable'),
          :mounted          => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'mounted'),
          :bridged          => true,
          :device           => "eth1",
          :vendor           => 'Broadcom',
          :model            => 'BCM5704',
          :driver           => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'driver'),
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :ip6              => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'ip6'),
          :switch           => "gw-lyon",
          :switch_port      => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'switch_port'),
          :mac              => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'eth1', 'mac')
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
          :ip               => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'bmc', 'ip'),
          :mac              => lookup('sagittaire_generated', node_uid, 'network_interfaces', 'bmc', 'mac'),
          :driver           => "bnx2"
        }]

        chassis({
          :serial       => lookup('sagittaire_generated', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('sagittaire_generated', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('sagittaire_generated', node_uid, 'chassis', 'manufacturer')
        })

        bios({
          :version      => lookup('sagittaire_generated', node_uid, 'bios', 'version'),
          :vendor       => lookup('sagittaire_generated', node_uid, 'bios', 'vendor'),
          :release_date => lookup('sagittaire_generated', node_uid, 'bios', 'release_date')
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
            :via => {
              :api => { :metric => 'pdu' },
              :www => { :url => 'https://helpdesk.grid5000.fr/supervision/lyon/wattmetre/GetWatts.php' },
            }
          }
        })
      end
    end
  end # cluster sagittaire
end
