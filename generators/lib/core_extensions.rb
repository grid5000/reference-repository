require 'json/pure'

module JSON
  module Pure
    module Generator
      module GeneratorMethods
        module Hash
          
          private
          # overwrites json/pure method
          def json_transform(state)
            delim = ','
            delim << state.object_nl
            result = '{'
            result << state.object_nl
            depth = state.depth += 1
            first = true
            indent = !state.object_nl.empty?
            keys.map{|k| k.to_s}.sort.each { |key|
              value = self[key] || self[key.to_sym]
              result << delim unless first
              result << state.indent * depth if indent
              result << key.to_s.to_json(state)
              result << state.space_before
              result << ':'
              result << state.space
              result << case value
                # no idea why this is not handled by json/pure
              when Fixnum
                value.to_s
              else
                value.to_json(state)
              end
              
              first = false
            }
            depth = state.depth -= 1
            result << state.object_nl
            result << state.indent * depth if indent if indent
            result << '}'
            result
          end
        end
      end
    end
  end
end

class Numeric

  def K;    self*10**3;     end
  def M;    self*10**6;     end
  def G;    self*10**9;     end
  def T;    self*10**12;    end

  {
    :KiB => 1024, :MiB => 1024**2, :GiB => 1024**3, :TiB => 1024**4,
    :KB => 1.K/1.024, :MB => 1.M/1.024**2, :GB => 1.G/1.024**3, :TB => 1.T/1.024**4
  }.each do |method, multiplier|
    define_method(method) do
      self*multiplier
    end
  end
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
