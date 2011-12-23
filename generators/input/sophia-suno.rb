site :sophia do |site_uid|

  cluster :suno do |cluster_uid|
    model "Dell PowerEdge R410"
    created_at Time.parse("2010-01-27").httpdate
    45.times do |i|
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
          :cache_l2 => 8.MiB
        })
        main_memory({
          :ram_size => 32.GiB, # bytes
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
          :size => 598.8.GB,
          :device => "sda",
          :model  => lookup('sophia-suno', node_uid, 'block_devices', 'sda', 'model'),
          :driver => "megaraid_sas",
          :raid => "0"
        }]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia-suno', node_uid, 'network_interfaces','eth0', 'mac'),
            :ip => lookup('sophia-suno', node_uid, 'network_interfaces','eth0', 'ip'),
            :vendor => 'Broadcom',
            :version => 'NetXtremeII BCM5716',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'bnx2',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :switch => lookup('sophia-suno', node_uid, 'network_interfaces','eth0', 'switch_name'),
            :switch_port => lookup('sophia-suno', node_uid, 'network_interfaces','eth0', 'switch_port')
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia-suno', node_uid, 'network_interfaces','eth0', 'mac'),
            :vendor => 'Broadcom',
            :version => 'NetXtremeII BCM5716',
            :enabled => false,
            :driver => 'bnx2',
            :device => 'eth1'
          },{
            :interface => 'Ethernet',
            :rate => 100.M,
            :network_address  => "#{node_uid}-bmc.#{site_uid}.grid5000.fr",
            :ip => lookup('sophia-suno', node_uid, 'network_interfaces','bmc', 'ip'),
            :mac => lookup('sophia-suno', node_uid, 'network_interfaces','bmc', 'mac'),
            :enabled  => true,
            :mounted => false,
            :mountable => false,
            :management => true,
            :device => "bmc"
          }]
          bios({
            :version => lookup('sophia-suno', node_uid, 'network_interfaces','version'),
            :vendor => lookup('sophia-suno', node_uid, 'network_interfaces','vendor'),
            :release_date => lookup('sophia-suno', node_uid, 'network_interfaces','release_date'),
          })
          chassis({
            :serial => lookup('sophia-suno', node_uid, 'chassis','serial_number'),
            :name => lookup('sophia-suno', node_uid, 'chassis','product_name'),
          })
      end
    end
  end

end
