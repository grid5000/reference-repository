environment 'lenny-x64-min-1.2' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-min-1.2.tgz", :md5 => "bcc63feb0afd26cb876c403bbca2f688"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , granduc , sagittaire , graphene , griffon , stremi , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, nano, Perl".split(", ")
  x11_forwarding true
  tcp_bandwidth 1.G
end
