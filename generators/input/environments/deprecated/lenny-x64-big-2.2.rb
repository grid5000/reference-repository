environment 'lenny-x64-big-2.2' do
  state "deprecated"
  file({:path => "/grid5000/images/lenny-x64-big-2.2.tgz", :md5 => "e87433ec446ef855a5f28a6a2fe44aaf"})
  available_on %w{}
  valid_on "griffon , grelon , sagittaire , capricorne , netgdx , gdx , bordeplage , bordereau , parapide , paramount , paraquad , azur , helios , sol , suno , edel , genepi , adonis , chuque , chinqchint , chicon , chti"
  kernel "2.6.26.2"
  available_on %w{}
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
