environment 'lenny-x64-xen-2.9' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-xen-2.9.tgz", :md5 => "a4fdff535af0f59b9b1f5df8b59b2068"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , granduc , hercule, orion, sagittaire, taurus, graphene , griffon , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim XEmacs JED nano JOE Perl Python Ruby}
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
