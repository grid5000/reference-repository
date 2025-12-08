require 'resolv' # Ip address validation

class HashValidator::Validator::LinecardPortValidator < HashValidator::Validator::Base
  def initialize
    super('linecard_port')
    @kind_values = %w[router switch backbone other channel server node]
    @port_validator = {
      'uid' => 'string',
      'name' => HashValidator.optional('string'),
      'port' => HashValidator.optional('string'),
      'kind' => HashValidator.optional('string'),
      'rate' => HashValidator.optional('integer'),
      'switchport_mode' => HashValidator.optional('switchport_mode'),
      'snmp_pattern' => HashValidator.optional('string'),
      'snmp_name' => HashValidator.optional('string'),
      'kavlan_pattern' => HashValidator.optional('string'),
      'ssh_name' => HashValidator.optional('string')
    }
  end

  def validate(key, values, _validations, errors)
    errors[key] = "Invalid '#{key}'. Should be an Integer" if key.class != Integer
    if values.is_a?(Hash)
      unless values.empty?
        validator = HashValidator.validate(values, @port_validator, true)
        errors[key] = validator.errors unless validator.valid?
        # defining kind as below does not work:
        # 'kind' => HashValidator.optional(@kind_values)
        # so we do a special case for it
        if values.has_key?('kind') && @kind_values.index(values['kind']).nil?
          errors[key] = "kind value #{values['kind']} must be one of #{@kind_values}"
        end
      end
    elsif values.is_a?(String) || values.is_a?(Numeric) || values.nil?
      # Allow any string and nil values
    else
      errors[key] =
        "port definition should be either empty, a String, a Numeric or a Hash (with required 'uid' and #{@port_properties} allowed properties)."
    end
  end
end

class HashValidator::Validator::SwitchportModeValidator < HashValidator::Validator::Base
  def initialize
    super('switchport_mode')
    @switchport_mode_values = %w[access trunk]
  end

  def validate(key, values, _validations, errors)
    return if @switchport_mode_values.include?(values)

    errors[key] = "Invalid switchport_mode value. Must be one of #{@switchport_mode_values}"
  end
end

class HashValidator::Validator::Ipv4AddressValidator < HashValidator::Validator::Base
  def initialize
    super('ipv4_address')
  end

  def validate(key, values, _validations, errors)
    if values.is_a?(String)
      errors[key] = "Invalid IPv4 address format #{values}" unless values =~ Resolv::IPv4::Regex
    else
      errors[key] = 'IPv4 address should be a String'
    end
  end
end

class HashValidator::Validator::Ipv4NetworkValidator < HashValidator::Validator::Base
  def initialize
    super('ipv4_network')
  end

  def validate(key, values, _validations, errors)
    if !values.is_a?(String)
      errors[key] = 'IPv4 network should be a String'
    elsif !values.include?('/')
      errors[key] = "IPv4 network should contain a '/' character"
    else
      address = values.split('/')[0]
      prefix_length = begin
        Integer(values.split('/')[1])
      rescue StandardError
        nil
      end
      if !prefix_length.is_a?(Integer) || prefix_length < 0 || prefix_length > 32
        errors[key] = "Invalid IPv4 prefix length for network #{values}"
      elsif !(address =~ Resolv::IPv4::Regex)
        errors[key] = "Invalid IPv4 network format #{values}"
      end
    end
  end
end

class HashValidator::Validator::Ipv6AddressValidator < HashValidator::Validator::Base
  def initialize
    super('ipv6_address')
  end

  def validate(key, values, _validations, errors)
    if values.is_a?(String)
      errors[key] = "Invalid IPv6 address format #{values}" unless values =~ Resolv::IPv6::Regex
    else
      errors[key] = 'IPv6 address should be a String'
    end
  end
end

class HashValidator::Validator::Ipv6NetworkValidator < HashValidator::Validator::Base
  def initialize
    super('ipv6_network')
  end

  def validate(key, values, _validations, errors)
    if !values.is_a?(String)
      errors[key] = 'IPv6 network should be a String'
    elsif !values.include?('/')
      errors[key] = "IPv6 network should contain a '/' character"
    else
      address = values.split('/')[0]
      prefix_length = begin
        Integer(values.split('/')[1])
      rescue StandardError
        nil
      end
      if !prefix_length.is_a?(Integer) || prefix_length < 0 || prefix_length > 128
        errors[key] = "Invalid IPv6 prefix length for network #{values}"
      elsif !(address =~ Resolv::IPv6::Regex)
        errors[key] = "Invalid IPv6 network format #{values}"
      end
    end
  end
end

HashValidator.append_validator(HashValidator::Validator::LinecardPortValidator.new)
HashValidator.append_validator(HashValidator::Validator::SwitchportModeValidator.new)
HashValidator.append_validator(HashValidator::Validator::Ipv4AddressValidator.new)
HashValidator.append_validator(HashValidator::Validator::Ipv4NetworkValidator.new)
HashValidator.append_validator(HashValidator::Validator::Ipv6AddressValidator.new)
HashValidator.append_validator(HashValidator::Validator::Ipv6NetworkValidator.new)
