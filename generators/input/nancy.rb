site :nancy do |site_uid|
  name "Nancy"
  location "Nancy, France"
  web "http://www.loria.fr"
  description ""
  latitude 48.7000
  longitude 6.2000
  sys_admin_contact "nancy-staff@lists.grid5000.fr"
  security_contact "nancy-staff@lists.grid5000.fr"
  user_support_contact "nancy-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-xen-1.0 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-xen-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :griffon do |cluster_uid|
    model "Carri System CS-5393B"
    created_at Time.parse("2009-04-10").httpdate
    92.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        serial lookup('nancy', node_uid, 'serial')
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
        storage_devices [{
          :interface => 'SATA II',
          :size => 320.GB,
          :driver => "ata_piix"
        }]
        network_adapters [{
          :interface => 'Ethernet',
          :rate => 1000000000,
          :device => "eth0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :switch => lookup('nancy', "#{node_uid}", 'switch_eth0'),
          :mac => lookup('nancy', "#{node_uid}", 'mac_eth0'),
          :switch_port => lookup('nancy', "#{node_uid}", 'switch_pos_eth0'), 
          :network_address => "#{node_uid}.#{site_uid}.grid5000.fr",
          :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
          :driver => "e1000e", :vendor => "intel", :version => "80003ES2LAN"
        },
        {
          :interface => 'Ethernet',
          :rate => 1000000000,
          :enabled => false,
          :mounted => false,
          :mac => lookup('nancy', "#{node_uid}", 'mac_eth1'),
          :mountable => false,
          :management => false,
          :driver => "e1000e", :vendor => "intel", :version => "BCM5721"
        },
	{
          :interface => 'InfiniBand',
          :rate => 20000000000,
          :device => "ib0",
          :enabled => true,
          :mounted => true,
          :mountable => true,
          :management => false,
          :ip => lookup('nancy', "#{node_uid}", 'ip_ib'),
          :network_address => "#{node_uid}-ib0.#{site_uid}.grid5000.fr",
	  :switch => "ib_switch",
          :ib_switch_card => lookup('nancy',"#{node_uid}", 'switch_ib_card'),
          :ib_switch_card_pos => lookup('nancy',"#{node_uid}", 'switch_ib_card_pos'),
          :driver => "mlx4_core", :vendor => "Mellanox", :version => " InfiniHost MT26418"
        },
        {
          :interface => 'InfiniBand',
          :rate => 20000000000,
          :enabled => false,
          :mountable => false,
          :mounted => false,
          :management => false
        },
        {
          :interface => 'Ethernet',
          :rate => 100000000,
          :enabled => true,
          :mounted => false,
          :mountable => false,
          :management => true,
          :vendor => "tyan", :version => "no",
          :ip => lookup('nancy', "#{node_uid}", 'ip_ipmi'),
          :network_address => "#{node_uid}-ipmi.#{site_uid}.grid5000.fr",
          :switch => lookup('nancy', "#{node_uid}", 'switch_ipmi'),
          :switch_port => lookup('nancy', "#{node_uid}", 'switch_ipmi_pos'),
          :mac => lookup('nancy', "#{node_uid}", 'mac_ipmi'),
          :pdu => lookup('nancy', "#{node_uid}", 'pdu'), :pdu_port => lookup('nancy', "#{node_uid}", 'pdu_pos')
        }]
      end
    end
  end # cluster griffon


end
