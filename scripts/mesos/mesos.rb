#!/usr/bin/ruby
# coding: utf-8

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'refrepo'
require 'json-schema'
mesos_schema = JSON::load(IO::read('mesocentre.schema.json'))

module Enumerable
  def sum
    collect(0) { |a,b| a + b }
  end
end

d = load_data_hierarchy
d['sites'].each_pair do |site, ds|
  o = {
    'name' => "Grid'5000 - #{site.capitalize}"
  }
  o['url'] = "https://www.grid5000.fr/w/#{site.capitalize}:Home"
  o['institutesName'] = case site
                        when 'grenoble' then ['CNRS', 'Inria', 'Université Grenoble Alpes']
                        when 'lille' then ['CNRS', 'Inria', 'Université de Lille']
                        when 'lyon' then ['CNRS', 'Inria', 'ENS Lyon']
                        when 'nancy' then ['CNRS', 'Inria', 'Université de Lorraine']
                        when 'nantes' then ['Inria', 'Université de Lorraine']
                        when 'rennes' then ['CNRS', 'Inria', 'Université Rennes 1']
                        when 'sophia' then ['CNRS', 'Inria', 'Université Côte d\'Azur']
                        when 'luxembourg' then ['Université du Luxembourg']
                        end
#  o['financersName'] = [] # FIXME
  o['fullDescription'] = "Grid'5000 est une infrastructure distribuée pour la recherche expérimentale dans tous les domaines de l'informatique, et en particulier pour le Cloud, le HPC, l'IA et le Big Data. Voir https://www.grid5000.fr/"
   o['serviceName'] = [
     'Infrastructure hautement reconfigurable et contrôlable: déploiement bare-metal d\'images systèmes, accès root sur les noeuds, reconfiguration réseau pour l\'isolation',
     'Système de monitoring pour diverses métriques (en particulier pour la consommation énergétique)',
     'Description très complète et traçabilité du matériel, pour une recherche reproductible'
   ]
  o['accessPolicy'] = [
    'Ouvert à la communauté de recherche en informatique, en particulier dans les domaines du Cloud, du HPC de l\'IA et du Big Data',
    'Ouvert aux chercheurs et ingénieurs d\'autres domaines scientifiques pour des travaux requiérant les services spécifiques offerts par Grid\'5000',
    'Ouvert aux entreprises moyennant paiement à l\'usage'
  ]
  o['location'] = case site
                  when 'grenoble' then 'Auvergne-Rhône-Alpes'
                  when 'lille' then 'Hauts-de-France'
                  when 'lyon' then 'Auvergne-Rhône-Alpes'
                  when 'nancy' then 'Grand Est'
                  when 'nantes' then 'Pays de la Loire'
                  when 'rennes' then 'Bretagne'
                  when 'sophia' then 'Provence-Alpes-Côte d\'Azur'
                  when 'luxembourg' then 'Etranger'
                  else raise
                  end
  o['GPSCoordinates'] = [ds['latitude'], ds['longitude']]
  o['contactName'], o['contactAddress'] = case site
                                           when 'grenoble' then ['Olivier Richard', 'olivier.richard@imag.fr']
                                           when 'lille' then ['Nouredine Melab', 'nouredine.melab@univ-lille.fr']
                                           when 'lyon' then ['Laurent Lefevre', 'laurent.lefevre@inria.fr']
                                           when 'nancy' then ['Lucas Nussbaum', 'lucas.nussbaum@loria.fr']
                                           when 'nantes' then ['Adrien Lèbre', 'adrien.lebre@inria.fr']
                                           when 'rennes' then ['Anne-Cécile Orgerie', 'anne-cecile.orgerie@irisa.fr']
                                           when 'sophia' then ['Fabrice Huet', 'fabrice.huet@unice.fr']
                                           when 'luxembourg' then ['Sébastien Varrette', 'sebastien.varrette@uni.lu']
                                           end
  o['distributedInfra'] = [ 'grid5000' ]
  o['clusterList'] = []
  ds['clusters'].each_pair do |cluster, dc|
    oc = {}
    oc['clusterName'] = cluster
    nodes = dc['nodes'].values.select { |n| not n['status'] == 'retired' }
    next if nodes.empty?
    fn = nodes.first
    oc['vendorName'] = case fn['chassis']['manufacturer']
                       when 'Dell Inc.' then 'Dell' # normalize according to schema
                       when 'HP' then 'HPE'
                       else fn['chassis']['manufacturer']
                       end

    oc['jobschedulerName'] = 'oar'
    oc['clusterCoreNumber'] = nodes.length * fn['architecture']['nb_cores']
    oc['nodeType'] = [
      {
        "CPUType" => "#{fn['processor']['model']} #{fn['processor']['version']}",
        "coreNumber" => fn['architecture']['nb_cores'],
        "cpuNumber" => fn['architecture']['nb_procs'], # FIXME check name of property
        "memory" => (fn['main_memory']['ram_size'].to_f / 1024**3).to_i,
        "nodeNumber" => nodes.length,
        "localDisk" => (fn['storage_devices'].map { |sd| sd['size'] }.sum.to_f / 1024**4).round(2)
      }
    ]
    if not fn['network_adapters'].select { |na| na['interface'] == 'InfiniBand' }.empty?
      oc['networkType'] = 'infiniband'
    elsif not fn['network_adapters'].select { |na| na['interface'] == 'Omni-Path' }.empty?
      oc['networkType'] = 'omni-path'
    else
      oc['networkType'] = 'ethernet'
    end
    oc['networkBandwidth'] = fn['network_adapters'].select { |e| e['mountable'] }.map { |e| e['rate'] }.max / 1000**3
    if (fn['gpu_devices'] || {}).values.length > 0
      gpus = fn['gpu_devices'].values
      oc['nodeType'].first['GPUType'] = "#{gpus.first['vendor']} #{gpus.first['model']}"
      oc['nodeType'].first['GPUNumber'] = gpus.length
    end
    o['clusterList'] << oc
  end
  o['storageList'] = []
  homesize = case site # size in To on 02/03/2020
             when 'grenoble' then 28
             when 'lille' then 6
             when 'lyon' then 14
             when 'nancy' then 91
             when 'nantes' then 11
             when 'rennes' then 10
             when 'sophia' then 41
             when 'luxembourg' then 10
             end
  o['storageList'] << {
    'typeName' => 'home',
    'name' => 'homes',
    'filesystemType' => 'NFS',
    'size' => homesize
  }
  # additional storage spaces
  if site == 'lille'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage1',
      'filesystemType' => 'NFS',
      'size' => 90
    }
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage2',
      'filesystemType' => 'NFS',
      'size' => 90
    }
  elsif site == 'lyon'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage1',
      'filesystemType' => 'NFS',
      'size' => 75
    }
  elsif site == 'rennes'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage1',
      'filesystemType' => 'NFS',
      'size' => 100
    }
  elsif site == 'nancy'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'talc-data',
      'filesystemType' => 'NFS',
      'size' => 71 + 58 + 58
    }
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'talc-data2',
      'filesystemType' => 'NFS',
      'size' => 200
    }
  elsif site == 'sophia'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage1',
      'filesystemType' => 'NFS',
      'size' => 30
    }
  elsif site == 'luxembourg'
    o['storageList'] << {
      'typeName' => 'data',
      'name' => 'storage1',
      'filesystemType' => 'NFS',
      'size' => 40
    }
  end
  o['totalCoreNumber'] = o['clusterList'].map { |c| c['clusterCoreNumber'] }.sum
  o['totalStorage'] = (o['clusterList'].map { |c| c['nodeType'].map { |n| n['localDisk'] * n['nodeNumber'] }.sum }.sum +
    o['storageList'].map { |s| s['size'] }.sum).round(2)
  JSON::Validator.validate!(mesos_schema, o)
  File::open("grid5000-#{site}.json", "w") { |fd| fd.puts JSON::pretty_generate(o) }
end

