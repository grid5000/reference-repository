site :lyon do |site_uid|

  cluster :hercule do |cluster_uid|
    model "Dell C6220"
    created_at Time.parse("2012-10-02 12:00 GMT").httpdate
    kavlan true
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
          :version => "E5-2620",
          :clock_speed => 2.0.G,
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
           :interface => 'SATA',
           :size      => 2.TB,
           :driver    => "ahci",
           :device    => "sda"
        },{
           :interface => 'SATA',
           :size      => 2.TB,
           :driver    => "ahci",
           :device    => "sdb"
        },{
           :interface => 'SATA',
           :size      => 2.TB,
           :driver    => "ahci",
           :device    => "sdc"
        },
        ]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 10.G,
          :vendor => 'Intel',
          :model => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :device => "eth1",
          :enabled => true,
          :management => false,
          :mountable => true,
          :mounted => true,
          :bridged => true,
          :driver => 'ixgbe',
          :network_address  => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip               => lookup('hercule', node_uid, 'network_interfaces', 'eth1', 'ip'),
          :switch           => "Force10",
          :switch_port      => lookup('hercule', node_uid, 'network_interfaces', 'eth1', 'switch_port'),
          :mac => lookup('hercule',"#{node_uid}",'network_interfaces','eth1','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 10.G,
          :vendor => 'Intel',
          :model => '82599EB 10-Gigabit SFI/SFP+ Network Connection',
          :device => "eth1",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'ixgbe',
          :mac => lookup('hercule',"#{node_uid}",'network_interfaces','eth0','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Corporation',
          :device => "eth2",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('hercule',"#{node_uid}",'network_interfaces','eth2','mac'),
        },
        {
          :interface => 'Ethernet',
          :rate => 1.G,
          :vendor => 'Intel',
          :model => 'Intel Corporation',
          :device => "eth3",
          :enabled => false,
          :management => false,
          :mountable => false,
          :mounted => false,
          :driver => 'igb',
          :mac => lookup('hercule',"#{node_uid}",'network_interfaces','eth3','mac'),
        }]
        monitoring({
          :wattmeter  => 'shared',
        })
        sensors({
          :power => {
            :available => true,
            :via => {
              :api => { :metric => 'pdu_shared' },
              :www => { :url => 'https://helpdesk.grid5000.fr/supervision/lyon/wattmetre/GetWatts.php' },
            }
          }
        })
      end
    end
  end # cluster hercule
end
