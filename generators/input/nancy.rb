site :nancy do |site_uid|
  name "Nancy"
  location "Nancy, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :grelon do |cluster_uid|
    model "HP ProLiant DL140G3"
    created_at Time.parse("2007-02-27 12:00 GMT").httpdate
    120.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        supported_job_types({:deploy => true, :besteffort => true, :virtual => "ivt"})
        architecture({
          :smp_size => 2, 
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "5110",
          :clock_speed => 1.6.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MiB
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
          {:interface => 'SATA', :size => 80.GB, :driver => "ata_piix"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, 
            :switch => "sgrelon1", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"}
          ]
      end
    end
  end # cluster grelon

  cluster :griffon do |cluster_uid|
    model "Carri System CS-5393B"
    created_at Time.parse("2009-04-10 12:00 GMT").httpdate
    92.times do |i|
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
          :version => "L5420",
          :clock_speed => 2.5.G,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 12.MiB
        })
        main_memory({
          :ram_size => 16.GiB,
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA II', :size => 320.GB, :driver => "ata_piix"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.G, :enabled => true, 
            :switch => "sgriffon1", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "e1000e", :vendor => "intel", :version => "80003ES2LAN"},
          {:interface => 'Ethernet', :rate => 1.G, :enabled => false, :driver => "e1000e", :vendor => "intel", :version => "BCM5721"},
	  {:interface => 'Infiniband 20G', :rate => 20.G, :enabled => true,
	    :switch => "ib_switch", :driver => "mlx4_core", :vendor => "Mellanox", :version => "MT26418" }
          ]
      end
    end
  end # cluster grelon


end
