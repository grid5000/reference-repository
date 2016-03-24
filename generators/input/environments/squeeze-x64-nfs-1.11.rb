environment 'squeeze-x64-nfs-1.11' do
  state "stable"
  file({:path => "/grid5000/images/squeeze-x64-nfs-1.11.tgz", :md5 => "30c060691f72754c031b3d0d58c673ac"})
  kernel "2.6.32-5"
  available_on %w{grenoble lille luxembourg lyon nancy nantes reims rennes sophia toulouse}
  valid_on "adonis , edel , genepi , chimint , chinqchint , chirloute , granduc , petitprince , hercule, orion, sagittaire, taurus, graphene , griffon , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version squeeze for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim XEmacs JED nano JOE Perl Python Ruby}
  x11_forwarding true
  max_open_files 65536
  tcp_bandwidth 1.G
end
