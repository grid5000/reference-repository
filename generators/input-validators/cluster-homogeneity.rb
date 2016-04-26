#!/usr/bin/ruby

# This script checks the cluste homogeneity

require 'pp'
require 'fileutils'
require 'pathname'
require 'hashdiff'

require '../lib/input_loader'

ignore_keys = %w(
  chassis.serial

  kavlan.kavlan-1
  kavlan.kavlan-2
  kavlan.kavlan-3
  kavlan.kavlan-4
  kavlan.kavlan-5
  kavlan.kavlan-6
  kavlan.kavlan-7
  kavlan.kavlan-8
  kavlan.kavlan-9
  kavlan.kavlan-10
  kavlan.kavlan-11
  kavlan.kavlan-12
  kavlan.kavlan-13
  kavlan.kavlan-14
  kavlan.kavlan-15
  kavlan.kavlan-16
  kavlan.kavlan-17
  kavlan.kavlan-18
  kavlan.kavlan-19
  kavlan.kavlan-20
  kavlan.kavlan-21

  network_adapters.bmc.ip
  network_adapters.bmc.mac
  network_adapters.bmc.network_address
  network_adapters.bmc.switch
  network_adapters.bmc.switch_port

  network_adapters.eth0.ip
  network_adapters.eth0.ip6
  network_adapters.eth0.mac
  network_adapters.eth0.network_address
  network_adapters.eth0.switch
  network_adapters.eth0.switch_port

  network_adapters.eth1.ip
  network_adapters.eth1.ip6
  network_adapters.eth1.mac
  network_adapters.eth1.switch_port

  network_adapters.eth2.ip
  network_adapters.eth2.ip6
  network_adapters.eth2.mac
  network_adapters.eth2.switch_port

  network_adapters.eth3.ip
  network_adapters.eth3.mac

  network_adapters.eth4.mac

  network_adapters.eth5.mac

  network_adapters.ib0.guid
  network_adapters.ib0.hwid
  network_adapters.ib0.ip
  network_adapters.ib0.ip6
  network_adapters.ib0.line_card
  network_adapters.ib0.position

  network_adapters.ib1.guid

  network_adapters.myri0.ip
  network_adapters.myri0.ip6
  network_adapters.myri0.mac
  network_adapters.myri0.network_address

  pdu.port
  pdu.uid

  storage_devices.sda.model
  storage_devices.sda.rev
  storage_devices.sda.size
  storage_devices.sda.timeread
  storage_devices.sda.timewrite
  storage_devices.sda.vendor

  storage_devices.sdc.model
  storage_devices.sdc.rev

  storage_devices.sde.model
  storage_devices.sde.rev

  supported_job_types.max_walltime
)

refapi_hash = load_yaml_file_hierarchy("../../input/grid5000/")

refapi_hash["sites"].each do |site_uid, site|
  site["clusters"].each do |cluster_uid, cluster|

    refnode_uid = cluster['nodes'].keys.sort.first
    refnode = cluster['nodes'][refnode_uid]
     
    cluster["nodes"].each_sort_by_node_uid do |node_uid, node|
      #next if node_uid != 'graphene-2'
      
      diffs = HashDiff.diff(refnode, node)
 
      # Remove keys that are specific to each nodes (ip, mac etc.)
      diffs.clone.each { |diff|
        diffs.delete(diff) if diff[0] == '~' && ignore_keys.include?(diff[1])
      }

      if !diffs.empty?
        puts "Differences between #{refnode_uid} and #{node_uid}:"
        pp diffs
      end

      # Remove the following line if you want to compare each nodes to the first cluster node
      refnode_uid = node_uid
      refnode = node

    end
  end
end
