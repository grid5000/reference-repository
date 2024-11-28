# frozen_string_literal: true

require 'refrepo/accesses'

VALID_TARGETS = %i[json history human].freeze
ACCESS_TARGETS = %i[json human].freeze

def generate_accesses_ir(list)
  targets = list.uniq & VALID_TARGETS

  if targets.include? :history
    history_data = generate_nodeset_mode_history
    write_mode_history(history_data)
  end

  return unless ACCESS_TARGETS.any? { |t| targets.include? t }

  access_data = expand_nodeset_lists
  write_access_json(access_data) if targets.include? :json
  write_human_readables(access_data) if targets.include? :human
end

def write_access_json(data)
  output_path = Pathname.new(output_dir).join('nodesets.json')
  File.delete(output_path) if File.exist?(output_path)
  generate_accesses_json(output_path, data)
end

def write_human_readables(data)
  output_path = Pathname.new(output_dir).join('nodesets.yaml')
  File.delete(output_path) if File.exist?(output_path)
  generate_accesses_yaml(output_path, data)
end

def write_mode_history(data)
  output_path = Pathname.new(output_dir).join('accesses_mode_history.yaml')
  File.delete(output_path) if File.exist?(output_path)
  generate_accesses_yaml(output_path, data)
end

def output_dir
  output_data_dir = '../../../data/grid5000/'
  refapi_path = File.expand_path(output_data_dir, File.dirname(__FILE__))
  Pathname.new(refapi_path).join('accesses')
end
