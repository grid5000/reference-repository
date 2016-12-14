module HashValidator::Validations
  class Array
    attr_reader :validation
    def initialize(validation)
      @validation = validation
    end
    
    def get_validation()
      @validation
    end
  end
  class NestedArray
    attr_reader :validation
    def initialize(validation)
      @validation = validation
    end

    def get_validation()
      @validation
    end
  end
end

class HashValidator::Validator::ArrayValidator < HashValidator::Validator::Base
  def initialize
    super('_array')
  end

  def should_validate?(rhs)
    rhs.is_a?(HashValidator::Validations::Array)
  end

  def validate(key, values, validations, errors)
    # Validate hash
    unless values.is_a?(Array)
      errors[key] = presence_error_message
      return
    end

    errors = (errors[key] = {})

    values.each_index do |i|
      HashValidator.validator_for(validations.get_validation()).validate(i, values[i], validations.get_validation(), errors)
    end

    # Cleanup errors (remove any empty nested errors)
    errors.delete_if { |k,v| v.empty? }
  end
end

class HashValidator::Validator::NestedArrayValidator < HashValidator::Validator::Base
  def initialize
    super('_nested_array')
  end

  def should_validate?(rhs)
    rhs.is_a?(HashValidator::Validations::NestedArray)
  end

  def validate(key, values, validations, errors)
    # Validate hash
    unless values.is_a?(Array)
      errors[key] = presence_error_message
      return
    end

    #Never alter original values, just make a copy
    validation_values = Marshal.load(Marshal.dump(values.flatten))

    errors = (errors[key] = {})

    validation_values.each_index do |i|
      HashValidator.validator_for(validations.get_validation()).validate(i, validation_values[i], validations.get_validation(), errors)
    end

    # Cleanup errors (remove any empty nested errors)
    errors.delete_if { |k,v| v.empty? }
  end
end

HashValidator.append_validator(HashValidator::Validator::ArrayValidator.new)
HashValidator.append_validator(HashValidator::Validator::NestedArrayValidator.new)
