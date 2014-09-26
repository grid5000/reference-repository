environment 'squeeze-x64-min-1.1' do
  state "stable"
  file({:path => "/grid5000/images/squeeze-x64-min-1.1.tgz", :md5 => "7121ff197adbdbaa09f501daec081ef8"})
  kernel "2.6.32-5"
  available_on %w{bordeaux grenoble lille lyon luxembourg nancy orsay reims rennes sophia toulouse}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , capricorne , sagittaire , granduc , graphene , griffon , gdx , netgdx , stremi , paramount , parapide , parapluie , helios , sol , suno, pastel , violette"
  based_on "Debian version squeeze for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim nano Perl}
  x11_forwarding true
  tcp_bandwidth 1.G
end
