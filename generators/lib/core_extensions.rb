class Numeric

  def TB(correct = true)
    if correct then self*1024**4; else self.tera/(1.024**4); end
  end
  # Returns the number of bytes.
  #
  # If you know that the provided number is not correct (in the case of hard drive capacities for example),
  # setting +correct+ to +false+ will return the "real" number of bytes (e.g. HD 160GB has in reality 149011611938.477 bytes).
  def GB(correct = true)
    if correct then self*1024**3; else self.giga/(1.024**3); end
  end
  def MB(correct = true)
    if correct then self*1024**2; else self.mega/(1.024**2); end
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
  
  
  # Returns a JSON string containing a JSON object, that is unparsed from
  # this Hash instance.
  # _state_ is a JSON::State object, that can also be used to configure the
  # produced JSON string output further.
  # _depth_ is used to find out nesting depth, to indent accordingly.
  # 
  # Contrary to the original implementation, the keys are *sorted*.
  # 
  def to_json(state = nil, depth = 0, *)
    if state
      state = JSON.state.from_state(state)
      state.check_max_nesting(depth)
      json_check_circular(state) { json_transform(state, depth) }
    else
      json_transform(state, depth)
    end
  end

  private

  def json_check_circular(state)
    if state and state.check_circular?
      state.seen?(self) and raise JSON::CircularDatastructure,
          "circular data structures not supported!"
      state.remember self
    end
    yield
  ensure
    state and state.forget self
  end

  def json_shift(state, depth)
    state and not state.object_nl.empty? or return ''
    state.indent * depth
  end

  def json_transform(state, depth)
    tmp_hash = {}
    self.each do |key, value|
      tmp_hash[key.to_s] = value
    end
    delim = ','
    delim << state.object_nl if state
    result = '{'
    result << state.object_nl if state
    result << tmp_hash.sort.map { |(key,value)|
      s = json_shift(state, depth + 1)
      s << key.to_s.to_json(state, depth + 1)
      s << state.space_before if state
      s << ':'
      s << state.space if state
      s << value.to_json(state, depth + 1)
    }.join(delim)
    result << state.object_nl if state
    result << json_shift(state, depth)
    result << '}'
    result
  end
  
end


# for versions of ruby < 1.8.7
module Enumerable
  def index_by
    inject({}) do |accum, elem|
      accum[yield(elem)] = elem
      accum
    end
  end

  def group_by #:yield:
    #h = k = e = nil
    r = Hash.new
    each{ |e| (r[yield(e)] ||= []) << e }
    r
  end  
end
