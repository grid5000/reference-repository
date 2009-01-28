
class Numeric

  def TB(correct = true)
    if correct then self*1024**4; else self.tera/(1024**4); end
  end
  # Returns the number of bytes.
  #
  # If you know that the provided number is not correct (in the case of hard drive capacities for example),
  # setting +correct+ to +false+ will return the "real" number of bytes (e.g. HD 160GB has in reality 149011611938.477 bytes).
  def GB(correct = true)
    if correct then self*1024**3; else self.giga/(1.024**3); end
  end
  def MB(correct = true)
    if correct then self*1024**2; else self.mega/(1024**2); end
  end
  def mega; self*1_000_000; end
  def giga; self*1_000_000_000; end
  def tera; self*1_000_000_000_000; end
end

class String
  # Really naive pluralization.
  # TODO: see if it's possible to include a better one (from rails or sthg else)
  def pluralize
    self+"s"
  end
end

class Hash
  def recursive_merge!(h)
    self.merge!(h) {|key, _old, _new| if _old.class == Hash then _old.recursive_merge!(_new) else _new end  }
  end  
end