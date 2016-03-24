environment 'wheezy-x64-nfs-1.3' do
  state "stable"
  file({:path => "/grid5000/images/wheezy-x64-nfs-1.3.tgz", :md5 => "b327d3150ef6f625f88ed65b08048cf9"})
  kernel "3.2.0-4"
  available_on %w{grenoble lille luxembourg lyon nancy nantes reims rennes sophia toulouse}
  valid_on "adonis , edel , genepi , chimint , chinqchint , chirloute , granduc , petitprince , hercule, orion, sagittaire, taurus, graphene , griffon , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version wheezy for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim XEmacs JED nano JOE Perl Python Ruby}
  x11_forwarding true
  max_open_files 65536
  tcp_bandwidth 1.G
end
