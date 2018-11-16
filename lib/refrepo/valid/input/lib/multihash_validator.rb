module HashValidator::Validations
  class Multi
    attr_reader :validation
    def initialize(validation)
      @validation = validation
    end
    
    def get_validation()
      @validation
    end
  end
end

class HashValidator::Validator::MultiHashValidator < HashValidator::Validator::Base
  def initialize
    super('_multihash')
  end

  def should_validate?(rhs)
    rhs.is_a?(HashValidator::Validations::Multi)
  end

  def validate(key, values, validations, errors)
    # pp "key: #{key} #{values} - #{validations}"

    # Validate hash
    unless values.is_a?(Hash)
      errors[key] = presence_error_message
      return
    end

    errors = (errors[key] = {})

    values.each do |k, v|
      HashValidator.validator_for(validations.get_validation()).validate(k, v, validations.get_validation(), errors)
    end

    # Cleanup errors (remove any empty nested errors)
    errors.delete_if { |k,v| v.empty? }
  end
end

HashValidator.append_validator(HashValidator::Validator::MultiHashValidator.new)
