site :orsay do |site_uid|
  name "Orsay"
  location "Orsay, France"
  web
  description ""
  latitude 48.7000
  longitude 2.2000
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}

  cluster :netgdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    30.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "246",
          :clock_speed => 2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => nil}
          ]
        network_adapters [{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :device => 'eth0',
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => nil
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
            :device => 'eth1',
            :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :switch => nil
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => nil,
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5703',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}-eth2.#{site_uid}.grid5000.fr",
            :device => 'eth2',
            :ip => dns_lookup("#{node_uid}-eth2.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]  
      end      
    end
  end # cluster net-gdx
  
  cluster :gdx do |cluster_uid|
    model "IBM eServer 326m"
    created_at nil
    misc "bios:1.28/bcm:1.20.17/bmc:1.10/rsaII:1.00"
    
    # WARN: 2 nodes are missing (gdx-311 and gdx-312) and won't appear in the reference
    (180+132-2).times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => false})
        architecture({
          :smp_size => 2, 
          :smt_size => 2,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "AMD",
          :model => "AMD Opteron",
          :version => "246",
          :clock_speed => 2.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 1.MiB
        })
        main_memory({
          :ram_size => 2.GiB, # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB, :driver => nil}
          ]
        network_adapters [{
            :interface => 'Myrinet',
            :rate => 10.G,
            :mac => nil,
            :vendor => 'Myrinet',
            :version => '10G-PCIE-8A-C',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => nil,
            :mounted => true,
            :network_address => "#{node_uid}-myri0.#{site_uid}.grid5000.fr",
            :device => 'myri0',
            :ip => dns_lookup("#{node_uid}-myri0.#{site_uid}.grid5000.fr"),
            :switch => nil
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('orsay', "#{node_uid}", 'mac_eth0'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => true,
            :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
            :device => 'eth0',
            :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :switch => nil
          },{
            :interface => 'Ethernet',
            :rate => 1.G,
            :mac => lookup('orsay', "#{node_uid}", 'mac_eth1'),
            :vendor => 'Broadcom',
            :version => 'NetXtreme BCM5780',
            :enabled => true,
            :management => false,
            :mountable => true,
            :driver => 'tg3',
            :mounted => false,
            :network_address => "#{node_uid}-eth1.#{site_uid}.grid5000.fr",
            :device => 'eth1',
            :ip => dns_lookup("#{node_uid}-eth1.#{site_uid}.grid5000.fr"),
            :switch => nil
          }]
      end        
    end
    
    # extension specifics, starting at node 181
    (132-2).times do |i|
      node "#{cluster_uid}-#{181+i}" do
        processor({
          :version => "250",
          :clock_speed => 2.4.G
        })
      end
    end
    
  end # cluster gdx
  
end
