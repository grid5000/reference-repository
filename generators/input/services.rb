# +policies+ is a hash describing the policies for authorizing or refusing access to a particular operation on a specific service:
#   * the key is the name of the operation (in the case of REST APIs, the operation should be one of the HTTP methods);
#   * the value is a hash that must contain:
#     - a comma separated list of +authorized_groups+ ("*" if no restriction),
#     - a +user_must_be_owner+ boolean indicating if the user requesting the resource must also own it and,
#     - a comma separated list of +admin_groups+, who will be able to access the resource even if they do not own it.
# No +policies+ means that the authorization decision is delegated to the API receiving the request.
service :authorization do
  name "Authorization"
  description "Returns the access policy for a particular service accessed by a given user."
  doc "/authorization/doc"
  uri "/authorization"
  contact "cyril.rohr@irisa.fr"
end

service :jobsets do
  name "Jobsets"
  description "Manages the creation/deletion and update of job sets."
  uri "/jobsets"
  doc "/jobsets/doc"
  policies( 'GET' => {:admin_groups => "CT", :authorized_groups => SITES.join(","), :user_must_be_owner => true},
            'POST' => {:admin_groups => "CT", :authorized_groups => SITES.join(","), :user_must_be_owner => true},
            'DELETE' => {:admin_groups => "CT", :authorized_groups => SITES.join(","), :user_must_be_owner => true},
            'PUT' => {:admin_groups => "CT", :authorized_groups => SITES.join(","), :user_must_be_owner => true}  )
end

service :statuses do
  name "Statuses"
  uri "/statuses"
  doc "/statuses/doc"
  contact "cyril.rohr@irisa.fr"
  description "Returns the status of a given resource."
end

service :oar do
  name "OAR"
  uri "/oar-site"
  doc
  contact "bruno.bzeznik@imag.fr"
  description
end