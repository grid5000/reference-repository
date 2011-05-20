site :sophia do |site_uid|
  name "Sophia-Antipolis"
  location "Sophia-Antipolis, France"
  web
  description ""
  latitude 43.6161
  longitude 7.0678
  email_contact "sophia-staff@lists.grid5000.fr"
  sys_admin_contact "sophia-staff@lists.grid5000.fr"
  security_contact "sophia-staff@lists.grid5000.fr"
  user_support_contact "sophia-staff@lists.grid5000.fr"
  ( %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  compilation_server false
    
  cluster :helios do |cluster_uid|
    model "Sun Fire X4100"
    created_at Time.parse("2006-06-02").httpdate
    56.times do |i|
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
          :version => "275",
          :clock_speed => 2.2.G,
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
          :name => "Debian",
          :release => "5.0",
          :version => nil
        })
        storage_devices [{
          :interface => 'SAS',
          :size => 73.GB,
          :driver => "mptsas",
          :raid => "0"
        },
        {
          :interface => 'SAS',
          :size => 73.GB,
          :driver => "mptsas",
          :raid => "0"
        }]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth0'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => "e1000",
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr")
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth1'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth1'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth2'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth2'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth3'),
            :vendor => 'Intel Corporation',
            :version => '82546EB',
            :enabled => false,
            :driver => 'e1000',
            :device => 'eth3'
          },{
            :interface => 'Myrinet',
            :rate => 2.G,
            :mac => nil,
            :vendor => 'Myricom',
            :version => 'M3F-PCIXF-2',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'mx',
            :mounted => true,
            :device => 'myri0',
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => "edgeiron48gs"
          }] 
      end
    end
  end
    
  cluster :sol do |cluster_uid|
    model "Sun Fire X2200 M2"
    created_at Time.parse("2007-02-23").httpdate
    50.times do |i|
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
          :name => "Debian",
          :release => "5.0",
          :version => nil
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 250.GB,
          :driver => "sata_nv"
        }]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth0'),
            :vendor => 'nVidia',
            :version => 'MCP55 Pro',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'forcedeth',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'fastiron'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth1'),
            :vendor => 'nVidia',
            :version => 'MCP55 Pro',
            :enabled => false,
            :driver => 'forcedeth',
            :device => 'eth1'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'BCM5715c',
            :enabled => false,
            :driver => 'tg3'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'BCM5715c',
            :enabled => false,
            :driver => 'tg3'
          }]
      end
    end
  end
  
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
          :release => "5.0",
          :version => nil
        })
        storage_devices [{
          :interface => 'SATA',
          :size => 598.8.GB,
          :driver => "megaraid_sas",
          :raid => "0"
        }]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtremeII BCM5716',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'bnx2',
            :mounted => true,
            :device => 'eth0',
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => 'fastiron'
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('sophia',"#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtremeII BCM5716',
            :enabled => false,
            :driver => 'bnx2',
            :device => 'eth1'
          }]
      end
    end
  end
  
end
