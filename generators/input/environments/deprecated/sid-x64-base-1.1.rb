environment 'sid-x64-base-1.1' do
  state "deprecated"
  file({:path => "/grid5000/images/sid-x64-base-1.1.tgz", :md5 => "756ccc2096e9feacde85500d33683dba"})
  available_on %w{}
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, HP DL385G2, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100"
  kernel "2.6.24"
  based_on "Debian version sid for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
