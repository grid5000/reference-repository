site :grenoble do |site_uid|
  name "Grenoble"
  location "Grenoble, France"
  web
  description ""
  latitude
  longitude
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  %w{sid-x64-base-1.0}.each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}

  cluster :genepi do |cluster_uid|
    model "Bull R422-E1"
    created_at Time.parse("2008-10-01").httpdate
    
    34.times do |i|
      node "#{cluster_uid}-#{i+1}" do |node_uid|
        architecture({
          :smp_size => 2, 
          :smt_size => 8,
          :platform_type => "x86_64"
          })
        processor({
          :vendor => "Intel",
          :model => "Intel Xeon",
          :version => "E5420 QC",
          :clock_speed => 2.5.giga,
          :instruction_set => "",
          :other_description => "",
          :cache_l1 => nil,
          :cache_l1i => nil,
          :cache_l1d => nil,
          :cache_l2 => nil
        })
        main_memory({
          :ram_size => 8.GB(true), # bytes
          :virtual_size => nil
        })
        operating_system({
          :name => nil,
          :release => nil,
          :version => nil
        })
        storage_devices [
          {:interface => 'SATA', :size => 160.GB(false), :driver => nil}
          ]
        network_adapters [
          ]  
      end      
    end
  end
end