environment 'lenny-x64-min-1.1' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-min-1.1.tgz", :md5 => "abf1a19b4f378f49c0b765a9d8eec059"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , granduc , capricorne , sagittaire , graphene , griffon , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, nano, Perl".split(", ")
  x11_forwarding true
  tcp_bandwidth 1.G
end
