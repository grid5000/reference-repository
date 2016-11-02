# YAML schema validator

# Inspired from XML DTD
# It uses https://github.com/jamesbrooks/hash_validator
# See also related tool: 
# * http://rx.codesimply.com/
# * http://www.kuwata-lab.com/kwalify/ruby/users-guide.html

dir = Pathname(__FILE__).parent

require 'json'
require 'hash_validator' # https://github.com/jamesbrooks/hash_validator
require "#{dir}/multihash_validator" # custom validator for <multi> array-like Hash support

# Simple required_hash validator
HashValidator.append_validator(HashValidator::Validator::SimpleValidator.new('required_hash', lambda { |v| v.is_a?(Hash) }))

# Date validator
HashValidator.append_validator(HashValidator::Validator::SimpleValidator.new('date', lambda { |v| v.is_a?(Date) }))

# Recursively replace 'optional_' values of the validation hash by HashValidator::Optional objects
def add_optional_validator(h)
  h.each_with_object({}) { |(k,v),g|
    g[k] = if (Hash === v) 
             add_optional_validator(v) 
           elsif String === v
             if v == 'optional_hash' || v == 'optional'
               HashValidator.optional('required')
             elsif v.start_with?('optional_') 
               HashValidator.optional(v.gsub('optional_', ''))
             else
               v
             end
           else
             v
           end
  }
end

# Recursively replace hash containing '<multi>' by HashValidator::MultiHash objects
def add_multihash_validator(h)
  h.each_with_object({}) { |(k,v),g|
    v = add_multihash_validator(v) if (Hash === v)
    g[k] = if (Hash === v)
             if v.key?('<multi>')
               HashValidator::Validations::Multi.new(v['<multi>'])
             elsif v.key?('<optional_hash>')
               HashValidator.optional(v['<optional_hash>'])
             else
               v
             end
           else
             v
           end
  }
end

# Monkey patching of the SimpleValidator to get more useful error messages
class HashValidator::Validator::SimpleValidator < HashValidator::Validator::Base
  def validate(key, value, validations, errors)
    unless lambda.call(value)
      errors[key] = "#{self.name} required (current value: #{value.class}:#{value})"
    end
  end
end

# Load validation schema from a YAML file
def load_yaml_schema(filename)
  schema = YAML::load_file(filename)
  schema = add_optional_validator(schema)
  schema = add_multihash_validator(schema)
end
