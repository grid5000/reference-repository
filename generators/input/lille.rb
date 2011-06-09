site :lille do |site_uid|
  name "Lille"
  location "Lille, France"
  web
  description ""
  latitude 50.6500
  longitude 3.0833
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact

cluster :chirloute do |cluster_uid|
    model "Dell PowerEdge C6100"
    created_at Time.parse("2011-03-25").httpdate
    8.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })                                                                                  
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon", 
          :version => "E5620",
          :clock_speed => 2.4.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil, 
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 12.MiB
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
          {:interface => 'SATA',
           :size => 300.GB,
           :driver => "mptsas",
           :raid => "0"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'eth0', 'mac'),
            :vendor => 'Intel',
            :version => '82576EB',
            :enabled => true, 
            :management => false,
            :mountable => true,
            :driver => 'igb',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'eth1', 'mac'),
            :vendor => 'Intel',
            :version => '82576EB',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'igb',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
            :switch_port => lookup('lille', node_uid, 'network_interfaces', 'eth1', 'switch_port')
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'bmc', 'mac'),
            :vendor => 'Inventec',
            :version => 1.14,
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-ipmi.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          }]
      end
    end
  end # cluster chirloute

  cluster :chimint do |cluster_uid|
    model "Dell PowerEdge R410"
    created_at Time.parse("2011-03-25").httpdate
    20.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2,
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5620",
          :clock_speed => 2.4.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 12.MiB
        })
        main_memory({
          :ram_size => 16.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', 
	   :size => 300.GB, 
	   :driver => "megaraid_sas",
	   :raid => "0"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'eth0', 'mac'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme II BCM5716',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'bnx2',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'eth1', 'mac'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme II BCM5716',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'bnx2',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
	    :switch_port => lookup('lille', node_uid, 'network_interfaces', 'eth1', 'switch_port')
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille', node_uid, 'network_interfaces', 'bmc', 'mac'),
            :vendor => 'Dell',
            :version => '1.54',
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-ipmi.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          }]
      end
    end
  end # cluster chimint


  cluster :chicon do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    26.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "285",
          :clock_speed => 2.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 4.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => "sata_svw"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_eth1'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false, 
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
            :switch_port => lookup('lille', "#{node_uid}", 'switch_port')
          },{
            :interface => 'Ethernet', 
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_mgt'),
            :vendor => 'IBM',
            :version => '1.18',
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-rsa.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-rsa.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
         },{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => "Myricom",
            :version => "10G-PCIE-8A-C",
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true, 
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
      end
    end
  end # cluster chicon
  
  cluster :chinqchint do |cluster_uid|
    model "Altix Xe 310"
    created_at nil
    46.times do |i|
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
          :version => "E5440 QC",
          :clock_speed => 2.83.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MiB
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
          {:interface => 'SATA II', :size => 250.GB, :driver => "ahci"}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_eth0'),
            :vendor => 'Intel',
            :version => '80003ES2LAN',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'e1000e',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}-eth0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-eth0.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_eth1'),
            :vendor => 'Intel',
            :version => '80003ES2LAN',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'e1000e',
            :mounted => true,
            :device => 'eth1',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'gw',
            :switch_port => lookup('lille', "#{node_uid}", 'switch_port')
         },{
            :interface => 'Ethernet', 
            :rate => 1.G,
            :mac => lookup('lille',"#{node_uid}", 'mac_mgt'),
            :vendor => 'Peppercon',
            :version => '1.46',
            :enabled => true,
            :management => true,
            :mountable => false,
            :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-ipmi.#{site_uid}.grid5000.fr"),
            :switch => 'gw'
          },{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => 'Myricom',
            :version => '10G-PCIE-8A-C',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true,
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
      end
    end
  end
  
end
