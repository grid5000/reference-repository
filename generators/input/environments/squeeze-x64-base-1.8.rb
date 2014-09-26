environment 'squeeze-x64-base-1.8' do
  state "stable"
  file({:path => "/grid5000/images/squeeze-x64-base-1.8.tgz", :md5 => "2f4f9fcf23c2107f78ac698477e20b7b"})
  kernel "2.6.32-5"
  available_on %w{grenoble lille luxembourg lyon nancy reims rennes sophia toulouse}
  valid_on "adonis , edel , genepi , chimint , chinqchint , chirloute , granduc , petitprince , hercule, orion, sagittaire, taurus, graphene , griffon , stremi , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version squeeze for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim XEmacs JED nano JOE Perl Python Ruby}
  x11_forwarding true
  max_open_files 65536
  tcp_bandwidth 1.G
end
