site :rennes do |site_uid|
  name "Rennes"
  location "Rennes, France"
  web "http://www.irisa.fr"
  description ""
  latitude 48.1000
  longitude -1.6667
  email_contact "rennes-staff@lists.grid5000.fr"
  sys_admin_contact "rennes-staff@lists.grid5000.fr"
  security_contact "rennes-staff@lists.grid5000.fr"
  user_support_contact "rennes-staff@lists.grid5000.fr"
  ( %w{sid-x64-base-1.0 sid-x64-base-1.1 sid-x64-nfs-1.0 sid-x64-nfs-1.1 sid-x64-big-1.1} + 
    %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
 compilation_server false
  
end
