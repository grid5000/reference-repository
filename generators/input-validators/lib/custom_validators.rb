
require "resolv" #Ip address validation

class HashValidator::Validator::LinecardPortValidator < HashValidator::Validator::Base

  def initialize
    super('linecard_port')
    @port_properties = ["uid", "name", "port", "kind", "mtu", "rate", "site"]
  end

  def validate(key, values, validations, errors)
    if values.is_a?(Hash)
      values.each do |k, v|
        if @port_properties.index(k) == nil
          errors[key] = "unexpected key '#{k}'."
        end
      end
      if values["uid"].nil? || values["uid"].empty?
        errors[key] = "port 'uid' property should be defined."
      end
    elsif values.is_a?(String) || values == nil
      #Allow any string and nil values
    else
      errors[key] = "port definition should be either empty, a String or a Hash (with required 'uid' and #{@port_properties} allowed properties)."
    end
  end
end

class HashValidator::Validator::IpAddressValidator < HashValidator::Validator::Base

  def initialize
    super('ip_address')
  end

  def validate(key, values, validations, errors)
    if values.is_a?(String)
      unless (values =~ Resolv::IPv4::Regex || values =~ Resolv::IPv6::Regex)
        errors[key] = "Invalid ip address format #{values}"
      end
    else
      errors[key] = "Ip address should be a String"
    end
  end
end

HashValidator.append_validator(HashValidator::Validator::LinecardPortValidator.new)
HashValidator.append_validator(HashValidator::Validator::IpAddressValidator.new)
