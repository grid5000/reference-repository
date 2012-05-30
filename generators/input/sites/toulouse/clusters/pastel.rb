site :toulouse do |site_uid|
  cluster :pastel do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-11-29").httpdate

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
          :clock_speed => 2613.M,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 8.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 250.GB, :driver => "sata_nv"}
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
            :switch_name => lookup('pastel', node_uid,'network_interfaces','eth0','switch_name')
          },
          { :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('pastel', node_uid, 'network_interfaces','eth1','mac'),
            :vendor => "NVIDIA",
            :version => "MCP55 Pro",
            :enabled => false,
            :management => false,
            :mountable => false,
            :mounted => false,
            :device => "eth1",
            :switch_name => nil
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
            :switch_name => '<unknown>'
          }
        ]
      end
    end
  end
end
