environment 'lenny-x64-big-2.1' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-2.1.tgz", :md5 => "b85027090ace01bb5fc34c951ec5d5b4"})
  available_on %w{bordeaux grenoble lille lyon nancy orsay rennes sophia toulouse}
  valid_on "griffon , grelon , sagittaire , capricorne , netgdx , gdx , bordeplage , bordereau , parapide , paramount , paraquad , paradent , azur , helios , sol , suno , edel , genepi , adonis , chuque , chinqchint , chicon , chti"
  kernel "2.6.26.2"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
