environment 'sid-x64-base-1.0' do
  state "stable"
  file({:path => "/grid5000/images/sid-x64-base-1.0.tgz", :md5 => "e39be32c087f0c9777fd0b0ad7d12050"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100"
  kernel "2.6.18-8"
  based_on "Debian version sid for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'sid-x64-base-1.1' do
  state "stable"
  file({:path => "/grid5000/images/sid-x64-base-1.1.tgz", :md5 => "756ccc2096e9feacde85500d33683dba"})
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

environment 'sid-x64-nfs-1.0' do
  state "stable"
  file({:path => "/grid5000/images/sid-x64-nfs-1.0.tgz", :md5 => "6e004d1ac25e86a1dadc09d28f968eb5"})
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

environment 'sid-x64-nfs-1.1' do
  state "stable"
  file({:path => "/grid5000/images/sid-x64-nfs-1.1.tgz", :md5 => "4218f5a9bfea4a759fa684db1ec4d89c"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100"
  kernel "2.6.24.3"
  based_on "Debian version sid for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'sid-x64-big-1.1' do
  state "stable"
  file({:path => "/grid5000/images/sid-x64-big-1.1.tgz", :md5 => "d514bee74404ed5f64ff41b2f60c4f7f"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100"
  kernel "2.6.24.3"
  based_on "Debian version sid for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'etch-x64-base-1.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-base-1.0.tgz", :md5 => "adcd603db66d9e3da98926174f7d69aa"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.18-6-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'etch-x64-base-1.1' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-base-1.1.tgz", :md5 => "457cc632376c2c4cefd975b36bf65072"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.18-6-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'etch-x64-nfs-1.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-nfs-1.0.tgz", :md5 => "c76462698ae0480aaa48c9b707b96da5"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'etch-x64-nfs-1.1' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-nfs-1.1.tgz", :md5 => "303740c75b7a74c94bb5909d3aa8ac4f"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'etch-x64-big-1.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-big-1.0.tgz", :md5 => "5ddf6e898c11846dfb3eb9b2def2d2de"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'etch-x64-big-1.1' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-big-1.1.tgz", :md5 => "6c971c97eb2f62c056e343cbe9f4a71d"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'etch-x64-xen-1.0' do
  state "testing"
  file({:path => "/grid5000/images/etch-x64-xen-1.0.tgz", :md5 => "42cd6233ff42d0c343a4a93ed6017d97"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.18-6-xen-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-base-0.9' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-0.9.tgz", :md5 => "c1913bf8de22f52ef213151c25208a4a"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.24.3"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-base-1.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-1.0.tgz", :md5 => "1b60d38c016b844024bc541efb212573"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.26.2"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-nfs-0.9' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-0.9.tgz", :md5 => "7975882dec6bde601346c0152e161638"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.24.3"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-nfs-1.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-1.0.tgz", :md5 => "89448d214db5477e3ac6ef39ed0e7f6e"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'lenny-x64-big-0.9' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-0.9.tgz", :md5 => "ead20673233d0b9162ba56481d596add"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.24.3"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services ['ldap', 'nfs']
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-big-1.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-1.0.tgz", :md5 => "b2e48586472579ac2b908816175e4aa6"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
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

environment 'lenny-x64-xen-1.0' do
  state "testing"
  file({:path => "/grid5000/images/lenny-x64-xen-1.0.tgz", :md5 => "3e292c686c3ed0b417e44fdde5ec1771"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310"
  kernel "2.6.26-2-xen-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'etch-x64-base-2.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-base-2.0.tgz", :md5 => "97ec1fa027e597ee54d7e38f6cd70472"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310i, Carri CS-5393B"
  kernel "2.6.18-6-amd64"
  based_on "Debian version etch for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'etch-x64-nfs-2.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-nfs-2.0.tgz", :md5 => "e564f3b80ba37eb01d967507a05dd5ca"})
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

environment 'etch-x64-big-2.0' do
  state "stable"
  file({:path => "/grid5000/images/etch-x64-big-2.0.tgz", :md5 => "b406634f4d0e0e5859c5ba7936064c2c"})
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

environment 'lenny-x64-base-2.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-2.0.tgz", :md5 => "43217a044daf45368231f405f7d63b59"})
  kernel "2.6.26.2"
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310, Carri CS-5393B"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}, {:login => "g5k", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-nfs-2.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-2.0.tgz", :md5 => "995f0dad8a0462b47e4fc22ae4e32369"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310, Carri CS-5393B"
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

environment 'lenny-x64-big-2.0' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-2.0.tgz", :md5 => "70a31ddd4db68c63b8364393dd379b75"})
  valid_on "Dell PE1855, Dell PE1950, HP DL140G3, HP DL145G2, IBM x3455, IBM e325, IBM e326, IBM e326m, Sun V20z, Sun X2200 M2, Sun X4100, Altix Xe 310, Carri CS-5393B"
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

environment 'lenny-x64-base-2.1' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-2.1.tgz", :md5 => "4d63ad5aa069916da98e3c074297db41"})
  kernel "2.6.26.2"
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

environment 'lenny-x64-nfs-2.1' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-2.1.tgz", :md5 => "b0756d201e0719c40785b746b8d5f395"})
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

environment 'lenny-x64-big-2.1' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-2.1.tgz", :md5 => "b85027090ace01bb5fc34c951ec5d5b4"})
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



environment 'lenny-x64-base-2.2' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-2.2.tgz", :md5 => "dedcda842737b61fc47d73b082edc9c4"})
  kernel "2.6.26.2"
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

environment 'lenny-x64-nfs-2.2' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-2.2.tgz", :md5 => "bd1ba75d86c226ba7e0e7153d892cc93"})
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

environment 'lenny-x64-big-2.2' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-2.2.tgz", :md5 => "e87433ec446ef855a5f28a6a2fe44aaf"})
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

environment 'lenny-x64-base-2.3' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-base-2.3.tgz", :md5 => "3c255364f601fc19271783269ef541c2"})
  kernel "2.6.26.2"
  valid_on "bordeplage , bordereau ,  adonis , edel , genepi , capricorne , sagittaire , graphene , griffon , gdx , netgdx , paradent , paramount , parapide , parapluie , helios , sol , suno"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-big-2.3' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-big-2.3.tgz", :md5 => "e5870c72c1a5386c287935dcf39a8a23"})
  kernel "2.6.26.2"
  valid_on "bordeplage , bordereau ,  adonis , edel , genepi , capricorne , sagittaire , graphene , griffon , gdx , netgdx , paradent , paramount , parapide , parapluie , helios , sol , suno"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-min-0.8' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-min-0.8.tgz", :md5 => "a39dcad30821b7404d8eb5ac1388f650"})
  kernel "2.6.26.2"
  valid_on "bordeplage , bordereau ,  adonis , edel , genepi , capricorne , sagittaire , graphene , griffon , gdx , netgdx , paradent , paramount , parapide , parapluie , helios , sol , suno"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, nano, Perl".split(", ")
  x11_forwarding true
  tcp_bandwidth 1.G
end

environment 'lenny-x64-nfs-2.3' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-nfs-2.3.tgz", :md5 => "12522a436a2790df866f1ecd63680eff"})
  kernel "2.6.26.2"
  valid_on "bordeplage , bordereau ,  adonis , edel , genepi , capricorne , sagittaire , graphene , griffon , gdx , netgdx , paradent , paramount , parapide , parapluie , helios , sol , suno"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

environment 'lenny-x64-xen-2.3' do
  state "stable"
  file({:path => "/grid5000/images/lenny-x64-xen-2.3.tgz", :md5 => "8e4f0eff055c61ed8a51265c1c9afd58"})
  kernel "2.6.26.2"
  valid_on "bordeplage , bordereau ,  adonis , edel , genepi , capricorne , sagittaire , graphene , griffon , gdx , netgdx , paradent , paramount , parapide , parapluie , helios , sol , suno"
  based_on "Debian version lenny for amd64"
  consoles [{:port => "ttyS0", :bps => 34800}]
  services []
  accounts [{:login => "root", :password => "grid5000"}]
  applications "Vim, XEmacs, JED, nano, JOE, Perl, Python, Ruby".split(", ")
  x11_forwarding true
  max_open_files 8192
  tcp_bandwidth 1.G
end

