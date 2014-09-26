environment 'lenny-x64-min-0.8' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-min-0.8.tgz", :md5 => "a39dcad30821b7404d8eb5ac1388f650"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , capricorne , sagittaire , graphene , griffon , gdx , netgdx , stremi , paramount , parapide , parapluie , helios , sol , suno, pastel , violette"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, nano, Perl".split(", ")
  x11_forwarding true
  tcp_bandwidth 1.G
end
