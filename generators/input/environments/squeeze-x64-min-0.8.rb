environment 'squeeze-x64-min-0.8' do
  state "stable"
  file({:path => "/grid5000/images/squeeze-x64-min-0.8.tgz", :md5 => "8aaaf11cb65279f0d747d2dd300fb3ce"})
  kernel "2.6.26.2"
  available_on %w{bordeaux grenoble lille lyon nancy orsay reims rennes sophia toulouse}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , capricorne , sagittaire , graphene , griffon , gdx , netgdx , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel , violette"
  based_on "Debian version squeeze for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim nano Perl}
  x11_forwarding true
  tcp_bandwidth 1.G
end
