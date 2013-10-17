environment 'wheezy-x64-min-1.4' do
  state "stable"
  file({:path => "/grid5000/images/wheezy-x64-min-1.4.tgz", :md5 => "206ce5c1a3cd856a4463c0a48324377f"})
  kernel "3.2.0-4"
  available_on %w{grenoble lille luxembourg lyon nancy reims rennes sophia toulouse}
  valid_on "adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , granduc , petitprince , hercule, orion, sagittaire, taurus, graphene , griffon , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel"
  based_on "Debian version wheezy for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications %w{Vim nano Perl}
  x11_forwarding true
  tcp_bandwidth 1.G
end
