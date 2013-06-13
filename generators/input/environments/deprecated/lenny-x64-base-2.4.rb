environment 'lenny-x64-base-2.4' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-base-2.4.tgz", :md5 => "20a563f24a6fad62ff764c23b56a959f"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "bordeplage , bordereau , borderline ,  adonis , edel , genepi , chicon , chimint , chinqchint , chirloute , capricorne , sagittaire , graphene , griffon , gdx , netgdx , stremi , paradent , paramount , parapide , parapluie , helios , sol , suno, pastel , violette"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
