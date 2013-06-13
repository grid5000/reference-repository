environment 'lenny-x64-base-2.1' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-base-2.1.tgz", :md5 => "4d63ad5aa069916da98e3c074297db41"})
  kernel "2.6.26.2"
  available_on %w{}
  valid_on "griffon , grelon , sagittaire , capricorne , netgdx , gdx , bordeplage , bordereau , parapide , paramount , paraquad , paradent , azur , helios , sol , suno , edel , genepi , adonis , chuque , chinqchint , chicon , chti"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
