site :orsay do |site_uid|
  name "Orsay"
  location "Orsay, France"
  web
  description ""
  latitude 48.7000
  longitude 2.2000
  email_contact
  sys_admin_contact
  security_contact
  user_support_contact
  ( %w{etch-x64-base-1.0 etch-x64-base-1.1 etch-x64-nfs-1.0 etch-x64-nfs-1.1 etch-x64-big-1.0 etch-x64-big-1.1 etch-x64-base-2.0 etch-x64-nfs-2.0 etch-x64-big-2.0} +
    %w{lenny-x64-base-0.9 lenny-x64-nfs-0.9 lenny-x64-big-0.9 lenny-x64-base-1.0 lenny-x64-nfs-1.0 lenny-x64-big-1.0 lenny-x64-base-2.0 lenny-x64-nfs-2.0 lenny-x64-big-2.0} +
    %w{lenny-x64-base-2.3 lenny-x64-big-2.3 lenny-x64-min-0.8 lenny-x64-nfs-2.3 lenny-x64-xen-2.3} +
    %w{squeeze-x64-base-0.8 squeeze-x64-big-0.8 squeeze-x64-min-0.8 squeeze-x64-nfs-0.8 squeeze-x64-xen-0.8}  ).each{|env_uid| environment env_uid, :refer_to => "grid5000/environments/#{env_uid}"}
  
end
