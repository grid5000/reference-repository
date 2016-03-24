environment 'sid-x64-nfs-1.0' do
  state "deprecated"
  file({:path => "/grid5000/images/sid-x64-nfs-1.0.tgz", :md5 => "6e004d1ac25e86a1dadc09d28f968eb5"})
  available_on %w{}
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100"
  kernel "2.6.18-4"
  based_on "Debian version sid for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
