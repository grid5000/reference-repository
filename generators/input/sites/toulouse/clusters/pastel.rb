site :toulouse do |site_uid|
  cluster :pastel do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-11-29").httpdate
    kavlan true

    140.times do |i|
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
          :clock_speed => 2600000000,
          :instruction_set => "x86-64",
          :other_description => "Dual-Core AMD Opteron(tm) Processor 2218",
          :cache_l1 => 65536,
          :cache_l1i => 65536,
          :cache_l1d => 65536,
          :cache_l3 => 0,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 8395284480,#8.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => "debian",
          :release => "Squeeze",
          :version => "6.0",
          :kernel  => "#1 SMP Debian 3.2.35-2"
        })
        storage_devices [
          {:interface => 'SATA',
           :size => 250056000000,#250.GB, #bytes
           :driver => "sata_nv",
           :device => "sda",
           :version => "V5DO"
          }
        ]
        network_adapters [
          { :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('pastel', node_uid, 'network_interfaces','eth0','mac'),
            :vendor => "NVIDIA",
            :version => "MCP55 Pro",
            :driver => "forcedeth",
            :enabled => true,
            :management => false,
            :mountable => true,
            :mounted => true,
            :bridged => true,
            :device => "eth0",
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => lookup('pastel', node_uid,'network_interfaces','eth0','ip'),
            :ip6 => nil,
            :switch => lookup('pastel', node_uid,'network_interfaces','eth0','switch_name'),
            :switch_port => lookup('pastel', node_uid,'network_interfaces','eth0','switch_port')
          },
          { :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('pastel', node_uid, 'network_interfaces','eth1','mac'),
            :vendor => "NVIDIA",
            :version => "MCP55 Pro",
            :driver => "forcedeth",
            :enabled => false,
            :management => false,
            :mountable => false,
            :mounted => false,
            :device => "eth1",
            :switch => nil
          },
          { :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('pastel', node_uid, 'network_interfaces','bmc','mac'),
            :vendor => "Broadcom",
            :version => "BCM5715c",
            :enabled => true,
            :management => true,
            :mountable => false,
            :mounted => false,
            :network_address => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => lookup('pastel', node_uid,'network_interfaces','bmc','ip'),
            :ip6 => nil,
            :switch => '<unknown>'
          }
        ]
        bios({
          :version	=> lookup('pastel', node_uid, 'bios', 'version'),
          :vendor	=> lookup('pastel', node_uid, 'bios', 'vendor'),
          :release_date	=> lookup('pastel', node_uid, 'bios', 'release_date')
        })
        chassis({
          :serial       => lookup('pastel', node_uid, 'chassis', 'serial_number'),
          :name         => lookup('pastel', node_uid, 'chassis', 'product_name'),
          :manufacturer => lookup('pastel', node_uid, 'chassis', 'manufacturer')
        })
        gpu({
           :gpu  => false
            })

        monitoring({
          :wattmeter  => false
        })
      end
    end
  end
end
