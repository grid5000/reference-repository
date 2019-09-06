#!/usr/bin/env ruby
require 'open3'
require 'json'

NVIDIA_DRIVER_MAJOR_MODE = 195

def detect_numa_node(complete_pci_bus_id)
  cmd = "cat /sys/class/pci_bus/" + complete_pci_bus_id + "/device/numa_node "
  numa_node = nil
  Open3.popen2(cmd) do |stdin, stdout, wait_thr|
    stdout.each do | line |
      numa_node = line.strip
    end
  end
  return numa_node
end

def detect_gpu_file_device(minor_number)
  cmd = "ls -lha /dev/nvidia*"
  device_file_path = nil
  Open3.popen2(cmd) do |stdin, stdout, wait_thr|
    stdout.each do | line |
      if line =~ /#{NVIDIA_DRIVER_MAJOR_MODE},\s+#{minor_number}/
        device_file_path = /\/dev.*/.match(line).to_s
      end
    end
  end
  return device_file_path
end

def fetch_nvdia_cards_info()
  cmd = "nvidia-smi -q"
  result = []
  Open3.popen2(cmd) do |stdin, stdout, wait_thr|
    minor_number = nil
    complete_pci_bus_id = nil

    stdout.each do |line|
      if line.include? "Minor Number"
        minor_number = line.split(":")[1].strip
      elsif line.include? "Bus Id"
        line_parts = line.split(":").map(&lambda {|x| x.strip})
        prefix_bus = line_parts[1].strip
        if prefix_bus.to_i == 0
          prefix_bus = "0000"
        end

        bus_id = line_parts[2].strip
        complete_pci_bus_id = prefix_bus + ":" + bus_id
      end

      if not minor_number.nil? and not complete_pci_bus_id.nil?
        numa_node = detect_numa_node(complete_pci_bus_id)
        gpu_file_device = detect_gpu_file_device(minor_number)
        gpu_info = {
            :minor_number => minor_number,
            :complete_pci_bus_id => complete_pci_bus_id,
            :numa_node => numa_node,
            :gpu_file_device => gpu_file_device
        }
        result.push(gpu_info)
        minor_number = nil
        complete_pci_bus_id = nil
      end
    end
  end
  return result
end

cards_info = fetch_nvdia_cards_info()
puts cards_info.to_json
