site :lyon do |site_uid|

  cluster :orion do |cluster_uid|
    model "Dell R720"
    created_at Time.parse("2012-09-14 12:00 GMT").httpdate
    kalvan false
    4.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2,
          :smt_size => 12,
          :platform_type => "x86_64"
        })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5-2630",
          :clock_speed => 2.3.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 32.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => "Debian",
          :release => "6.0",
          :version => nil,
          :kernel => "2.6.32"
        })
        storage_devices [{
           :interface => 'SCSI',
           :size      => 598.GB,
           :driver    => "megaraid_sas",
           :device    => "sda"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 10.G,
          :vendor => 'Intel',
          :model => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :device => "eth0",
          :enabled => true,
          :management => false,
          :mountable => true,
          :mounted => true,
          :bridged => true,
          :driver => 'ixgbe',
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('orion', node_uid, 'network_interfaces', 'eth0', 'ip'),
          :switch           => "Force10",
          :switch_port      => lookup('orion', node_uid, 'network_interfaces', 'eth0', 'switch_port'),
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth0','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 10.G,
          :vendor => 'Intel',
          :model => 'Intel X520 DP 10Gb DA/SFP+ Server Adapter',
          :device => "eth1",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'ixgbe',
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth2','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Ethernet I350 QP 1Gb',
          :device => "eth2",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth2','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Ethernet I350 QP 1Gb',
          :device => "eth3",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth3','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Ethernet I350 QP 1Gb',
          :device => "eth4",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth4','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Ethernet I350 QP 1Gb',
          :device => "eth5",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('orion',"#{node_uid}",'network_interfaces','eth5','mac'),
        }]
        monitoring({
          :wattmeter  => true
        })
        gpu({
          :gpu         =>  true,
          :gpu_count   =>  1,
          :gpu_model   =>  "Tesla-M2075",
        })
      end
    end
  end # cluster orion
end
