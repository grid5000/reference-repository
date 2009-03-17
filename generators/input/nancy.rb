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
  %w{sid-x64-base-1.0}.each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
  cluster :grelon do |cluster_uid|
    model "HP ProLiant DL140G3"
    created_at Time.parse("2007-02-27 12:00 GMT").httpdate
    120.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        architecture({
          :smp_size => 2, 
          :smt_size => 4,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "5110",
          :clock_speed => 1.6.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => 4.MB
        })
        main_memory({
          :ram_size => 2.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 80.GB(false), :driver => "ata_piix"}
          ]
        network_adapters [
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, 
            :switch => "sgrelon1", :network_address => "#{node_uid}.#{site_uid}.grid5000.fr", :ip => dns_lookup("#{node_uid}.#{site_uid}.grid5000.fr"),
            :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"},
          {:interface => 'Ethernet', :rate => 1.giga, :enabled => true, :driver => "tg3", :vendor => "Broadcom", :version => "BCM5721"}
          ]
      end
    end
  end # cluster grelon
end