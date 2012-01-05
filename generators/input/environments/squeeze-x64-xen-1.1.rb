environment 'squeeze-x64-xen-1.1' do
  state "stable"
  file({:path => "/grid5000/images/squeeze-x64-xen-1.1.tgz", :md5 => "3fb6302e4ef1949063cdacd952ce8487"})
  kernel "2.6.32-5"
  available_on %w{bordeaux grenoble lille lyon luxembourg nancy orsay reims rennes sophia toulouse}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , capricorne , sagittaire , granduc , graphene , griffon , gdx , netgdx , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel , violette"
  based_on "Debian version squezze for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim XEmacs JED nano JOE Perl Python Ruby}
  x11_forwarding true
  max_open_files 65536
  tcp_bandwidth 1.G
end
