# Load a hierarchy of YAML file into a Ruby hash

require 'refrepo/hash/hash'

def load_yaml_file_hierarchy(directory = File.expand_path("../../input/grid5000/", File.dirname(__FILE__)))

  global_hash = {} # the global data structure
  
  Dir.chdir(directory) {
  
    # Recursively list the .yaml files.
    # The order in which the results are returned depends on the system (http://ruby-doc.org/core-2.2.3/Dir.html).
    # => List deepest files first as they have lowest priority when hash keys are duplicated.
    list_of_yaml_files = Dir['**/*.y*ml', '**/*.y*ml.erb'].sort_by { |x| -x.count('/') }
    
    list_of_yaml_files.each { |filename|
      begin
        # Load YAML
        if /\.y.*ml\.erb$/.match(filename)
          # For files with .erb.yaml extensions, process the template before loading the YAML.
          file_hash = YAML::load(ERB.new(File.read(filename)).result(binding))
        else
          file_hash = YAML::load_file(filename)
        end
      if not file_hash
        raise Exception.new("loaded hash is empty")
      end
      # YAML::Psych raises an exception if the file cannot be loaded.
      rescue StandardError => e
        puts "Error loading '#{filename}', #{e.message}"
      end

      # Inject the file content into the global_hash, at the right place
      path_hierarchy = File.dirname(filename).split('/')     # Split the file path (path relative to input/)
      path_hierarchy = [] if path_hierarchy == ['.']

      file_hash = Hash.from_array(path_hierarchy, file_hash) # Build the nested hash hierarchy according to the file path
      global_hash = global_hash.deep_merge(file_hash)        # Merge global_hash and file_hash. The value for entries with duplicate keys will be that of file_hash

      # Expand the hash. Done at each iteration for enforcing priorities between duplicate entries:
      # ie. keys to be expanded have lowest priority on existing entries but higher priority on the entries found in the next files
      global_hash.expand_square_brackets(file_hash)

    }

  }

#  pp global_hash

  # populate each node with its kavlan IPs
  add_kavlan_ips(global_hash)

  return global_hash

end

# Allocation of VLAN offsets (relative to VLAN IPs from https://www.grid5000.fr/w/Grid5000:Network )
# Please keep this sorted. After modification, use: ruby -Ilib -rrefrepo/input_loader -e sorted_vlan_offsets
# Max addresses are:
#   local: 15.255 (/20 network) -- overlap between sites is OK
#   global: 63.255 (/18 network)
#   routed: SITEID.63.255 (/18 network per site)
VLAN_OFFSET=<<-EOF
local grenoble yeti eth0 0 0 2 110
local grenoble dahu eth0 0 0 2 120
local lille chetemi eth0 0 0 0 0
local lille chetemi eth1 0 0 0 15
local lille chifflet eth0 0 0 1 0
local lille chifflet eth1 0 0 1 8
local lille chifflot eth0 0 0 2 0
local lille chifflot eth1 0 0 2 8
local lille chiclet eth0 0 0 3 0
local lille chiclet eth1 0 0 3 8
local luxembourg granduc eth0 0 0 1 0
local luxembourg granduc eth1 0 0 2 0
local luxembourg petitprince eth0 0 0 3 0
local luxembourg petitprince eth1 0 0 4 0
local lyon sagittaire eth1 0 0 0 0
local lyon taurus eth0 0 0 0 79
local lyon orion eth0 0 0 0 95
local lyon hercule eth1 0 0 0 99
local lyon nova eth0 0 0 0 111
local nancy griffon eth0 0 0 1 0
local nancy graphene eth0 0 0 2 0
local nancy grcinq eth0 0 0 3 0
local nancy grvingt eth0 0 0 3 48
local nancy graphite eth0 0 0 4 0
local nancy graphique eth0 0 0 8 0
local nancy graoully eth0 0 0 9 0
local nancy graoully eth0 0 0 10 0
local nancy grimoire eth0 0 0 10 0
local nancy grisou eth0 0 0 11 0
local nancy grisou eth1 0 0 11 60
local nancy grisou eth2 0 0 11 120
local nancy grisou eth3 0 0 11 180
local nancy grimani eth0 0 0 12 0
local nancy grisou eth4 0 0 12 6
local nancy grele eth0 0 0 12 57
local nantes econome eth0 0 0 0 0
local nantes ecotype eth0 0 0 1 0
local nantes ecotype eth1 0 0 1 48
local rennes parapide eth0 0 0 3 0
local rennes parapluie eth1 0 0 4 0
local rennes paranoia eth0 0 0 5 0
local rennes paranoia eth2 0 0 6 0
local rennes paranoia eth1 0 0 7 0
local rennes paravance eth0 0 0 8 0
local rennes paravance eth1 0 0 9 0
local rennes parasilo eth0 0 0 12 0
local rennes parasilo eth1 0 0 13 0
local sophia suno eth0 0 0 3 0
local sophia uvb eth0 0 0 5 0
global grenoble yeti eth0 0 0 2 110
global grenoble dahu eth0 0 0 2 120
global lille chetemi eth0 0 0 4 0
global lille chetemi eth1 0 0 4 15
global lille chifflet eth0 0 0 4 30
global lille chifflet eth1 0 0 4 38
global lille chifflot eth0 0 0 4 46
global lille chifflot eth1 0 0 4 54
global lille chiclet eth0 0 0 4 62
global lille chiclet eth1 0 0 4 70
global lyon sagittaire eth1 0 0 6 0
global lyon taurus eth0 0 0 6 79
global lyon orion eth0 0 0 6 95
global lyon hercule eth1 0 0 6 99
global lyon nova eth0 0 0 6 111
global nancy grele eth0 0 0 8 0
global nancy griffon eth0 0 0 8 0
global nancy graphene eth0 0 0 8 92
global nancy graphite eth0 0 0 8 236
global nancy grcinq eth0 0 0 9 0
global nancy grvingt eth0 0 0 9 48
global nancy graphique eth0 0 0 9 142
global nancy graoully eth0 0 0 9 148
global nancy grimoire eth0 0 0 9 165
global nancy grisou eth0 0 0 9 174
global nancy grimani eth0 0 0 9 225
global rennes paravance eth0 0 0 12 1
global rennes paravance eth1 0 0 12 73
global rennes parasilo eth0 0 0 12 145
global rennes parasilo eth1 0 0 12 173
global rennes paranoia eth0 0 0 12 201
global rennes paranoia eth1 0 0 12 209
global rennes paranoia eth2 0 0 12 217
global rennes parapide eth0 0 0 12 225
global rennes parapluie eth1 0 0 13 1
global sophia uvb eth0 0 0 16 0
global sophia suno eth0 0 0 16 106
global luxembourg granduc eth0 0 0 20 0
global luxembourg granduc eth1 0 0 20 22
global luxembourg petitprince eth0 0 0 21 0
global luxembourg petitprince eth1 0 0 21 16
global nantes econome eth0 0 0 22 0
global nantes ecotype eth0 0 0 22 22
global nantes ecotype eth1 0 0 22 70
routed grenoble yeti eth0 0 4 2 110
routed grenoble dahu eth0 0 4 2 120
routed lille chetemi eth0 0 8 0 0
routed lille chetemi eth1 0 8 0 15
routed lille chifflet eth0 0 8 1 0
routed lille chifflet eth1 0 8 1 8
routed lille chifflot eth0 0 8 2 0
routed lille chifflot eth1 0 8 2 8
routed lille chiclet eth0 0 8 3 0
routed lille chiclet eth1 0 8 3 8
routed lyon sagittaire eth1 0 12 0 0
routed lyon taurus eth0 0 12 0 79
routed lyon orion eth0 0 12 0 95
routed lyon hercule eth1 0 12 0 99
routed lyon nova eth0 0 12 0 111
routed nancy griffon eth0 0 16 1 0
routed nancy graphene eth0 0 16 2 0
routed nancy grcinq eth0 0 16 3 0
routed nancy grvingt eth0 0 16 3 48
routed nancy graphite eth0 0 16 4 0
routed nancy graphique eth0 0 16 9 0
routed nancy graoully eth0 0 16 10 0
routed nancy grimoire eth0 0 16 11 0
routed nancy grisou eth0 0 16 12 0
routed nancy grisou eth1 0 16 12 60
routed nancy grisou eth2 0 16 12 120
routed nancy grisou eth3 0 16 12 180
routed nancy grimani eth0 0 16 13 0
routed nancy grisou eth4 0 16 13 6
routed nancy grele eth0 0 16 13 57
routed rennes parapide eth0 0 24 3 0
routed rennes parapluie eth1 0 24 4 0
routed rennes paranoia eth0 0 24 5 0
routed rennes paranoia eth2 0 24 6 0
routed rennes paranoia eth1 0 24 7 0
routed rennes paravance eth0 0 24 8 0
routed rennes paravance eth1 0 24 9 0
routed rennes parasilo eth0 0 24 12 0
routed rennes parasilo eth1 0 24 13 0
routed sophia suno eth0 0 32 3 0
routed sophia uvb eth0 0 32 5 0
routed luxembourg granduc eth0 0 40 1 0
routed luxembourg granduc eth1 0 40 1 22
routed luxembourg granduc eth1 0 40 2 0
routed luxembourg petitprince eth0 0 40 3 0
routed luxembourg petitprince eth1 0 40 4 0
routed nantes econome eth0 0 44 0 0
routed nantes ecotype eth0 0 44 1 0
routed nantes ecotype eth1 0 44 1 48
EOF

# FIXME missing clusters / interfaces:
# NO VLAN OFFSET: ["local", "nancy", "grimoire", "eth1"] / grimoire-8-eth1-kavlan-1.nancy.grid5000.fr
# NO VLAN OFFSET: ["routed", "nancy", "grimoire", "eth1"] / grimoire-8-eth1-kavlan-4.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grimoire", "eth1"] / grimoire-8-eth1-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["local", "nancy", "grimoire", "eth2"] / grimoire-8-eth2-kavlan-1.nancy.grid5000.fr
# NO VLAN OFFSET: ["routed", "nancy", "grimoire", "eth2"] / grimoire-8-eth2-kavlan-4.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grimoire", "eth2"] / grimoire-8-eth2-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["local", "nancy", "grimoire", "eth3"] / grimoire-8-eth3-kavlan-1.nancy.grid5000.fr
# NO VLAN OFFSET: ["routed", "nancy", "grimoire", "eth3"] / grimoire-8-eth3-kavlan-4.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grimoire", "eth3"] / grimoire-8-eth3-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grisou", "eth1"] / grisou-43-eth1-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grisou", "eth2"] / grisou-43-eth2-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grisou", "eth3"] / grisou-43-eth3-kavlan-11.nancy.grid5000.fr
# NO VLAN OFFSET: ["global", "nancy", "grisou", "eth4"] / grisou-43-eth4-kavlan-11.nancy.grid5000.fr

def sorted_vlan_offsets
  offsets = VLAN_OFFSET.split("\n").
   map { |l| l = l.split(/\s+/) ; (4..7).each { |e| l[e] = l[e].to_i } ; l }
  # for local VLANs, we include the site when we sort
  puts offsets.select { |l| l[0] == 'local' }.
   sort_by { |l| [l[0], l[1] ] + l[4..-1] }.
   map { |l| l.join(' ') }.
   join("\n")
  puts offsets.select { |l| l[0] != 'local' }.
   sort_by { |l| [l[0] ] + l[4..-1] }.
   map { |l| l.join(' ') }.
   join("\n")

end

VLAN_OFFSET_H = VLAN_OFFSET.split("\n").map { |l| l = l.split(/\s+/) ; [ l[0..3], l[4..-1].inject(0) { |a, b| (a << 8) + b.to_i } ] }.to_h

VLAN_BASE = {
  1 => IPAddress::IPv4::new("192.168.192.0").to_u32,
  2 => IPAddress::IPv4::new("192.168.208.0").to_u32,
  3 => IPAddress::IPv4::new("192.168.224.0").to_u32,
  4 => IPAddress::IPv4::new("10.0.0.0").to_u32,
  5 => IPAddress::IPv4::new("10.0.64.0").to_u32,
  6 => IPAddress::IPv4::new("10.0.128.0").to_u32,
  7 => IPAddress::IPv4::new("10.0.192.0").to_u32,
  8 => IPAddress::IPv4::new("10.1.0.0").to_u32,
  9 => IPAddress::IPv4::new("10.1.64.0").to_u32,
  11 => IPAddress::IPv4::new("10.7.192.0").to_u32,
  12 => IPAddress::IPv4::new("10.11.192.0").to_u32,
  13 => IPAddress::IPv4::new("10.15.192.0").to_u32,
  14 => IPAddress::IPv4::new("10.19.192.0").to_u32,
  16 => IPAddress::IPv4::new("10.27.192.0").to_u32,
  18 => IPAddress::IPv4::new("10.35.192.0").to_u32,
  20 => IPAddress::IPv4::new("10.43.192.0").to_u32,
  21 => IPAddress::IPv4::new("10.47.192.0").to_u32,
}
UNUSED_VLANS = [10, 15, 17, 19 ] # removed sites

# this was useful when doing the initial import
GET_FROM_DNS = false

$tried_resolv = {}
$allocated = {}
def add_kavlan_ips(h)
  h['sites'].each_pair do |site_uid, hs|
    p site_uid
    hs['clusters'].each_pair do |cluster_uid, hc|
      hc['nodes'].each_pair do |node_uid, hn|
        # raise "Old kavlan data in input/ for #{node_uid}" if hn.has_key?('kavlan') # FIXME uncomment after input/ is cleaned up
        node_id = node_uid.split('-')[1].to_i
        hn['kavlan'] = {}
        hn['network_adapters'].to_a.select { |i| i[1]['mountable'] and (i[1]['kavlan'] or not i[1].has_key?('kavlan')) and i[1]['interface'] == 'Ethernet' }.map { |e| e[0] }.each do |iface|
          hn['kavlan'][iface] = {}
          (1..21).each do |vlan|
            type = 'local' if vlan <= 3
            type = 'routed' if vlan >= 4 and vlan <= 9
            type = 'global' if vlan >= 10
            next if UNUSED_VLANS.include?(vlan)
            k = [type, site_uid, cluster_uid, iface]
            if not VLAN_OFFSET_H.has_key?(k)
              puts "Missing VLAN offset for #{k}"
              if GET_FROM_DNS
                puts "Trying to get from DNS..."
                next if $tried_resolv[k]
                $tried_resolv[k] = true
                host = "#{node_uid}-#{iface}-kavlan-#{vlan}.#{site_uid}.grid5000.fr"
                begin
                  ip = IPSocket.getaddress(host)
                  puts "#{host} => #{ip} / base= #{IPAddress::IPv4::parse_u32(VLAN_BASE[vlan])}"
                  offset = IPAddress::IPv4::new(ip).to_u32 - VLAN_BASE[vlan] - node_id
                  puts "NEW VLAN OFFSET: #{type} #{site_uid} #{cluster_uid} #{iface} #{IPAddress::IPv4::parse_u32(offset).octets.join(' ')}"
                rescue SocketError
                  puts "NO VLAN OFFSET: #{k} / #{host}"
                end
              end
              next
            end
            ip = IPAddress::IPv4::parse_u32(VLAN_BASE[vlan] + VLAN_OFFSET_H[k] + node_id)
            raise "IP already allocated: #{ip} (trying to add it to #{node_uid}-#{iface})" if $allocated[ip]
            $allocated[ip] = true
            hn['kavlan'][iface]["kavlan-#{vlan}"] = ip
          end
        end
      end
    end
  end
end
