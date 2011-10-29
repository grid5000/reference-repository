environment 'etch-x64-nfs-2.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-nfs-2.0.tgz", :md5 => "e564f3b80ba37eb01d967507a05dd5ca"})
  available_on %w{bordeaux grenoble lille lyon nancy orsay rennes sophia toulouse}
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310, Carri CS-5393B"
  kernel "2.6.18-6-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end
