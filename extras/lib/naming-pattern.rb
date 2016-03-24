
class NamingPattern

  # Encode a naming pattern into a hash containing the keys and decoded values
  #
  # Vlan%VLANID% + Vlan101    =>   {"vlanid"=>101}
  # Po%CHANNELID% + Po2     =>   {"channelid"=>2}
  # Gi%LINECARD%/%PORT% + Gi2/7     =>   {"linecard"=>2, "port"=>7}
  # Te%LINECARD%/%PORT% + Te2/7     =>   {"linecard"=>2, "port"=>7}
  # Gi%STACK%/%LINECARD%/%PORT% + Gi2/4/5     =>   {"stack"=>2, "linecard"=>4, "port"=>5}
  # Gi2/%LINECARD%/%PORT% + Gi2/4/5     =>   {"linecard"=>4, "port"=>5}
  # Te2/%LINECARD%/%PORT% + Te2/4/5     =>   {"linecard"=>4, "port"=>5}
  # %LINECARD:A%%PORT% + D5     =>   {"linecard"=>3, "port"=>5}
  # %LINECARD%%PORT:a% + 3d     =>   {"linecard"=>3, "port"=>3}
  def self.encode(pattern,name)
    keys = pattern.scan(/%([^%]+)%/).flatten
    return {} if keys.nil?
    # protect the naming pattern from regexp interpretation
    reg = pattern.gsub('/','\/')
    keys.each do |key_type|
      key,type = key_type.split(/:([^:]+$)/)
      type = '1' if type.nil?
      reg_key_type = Regexp.new("%#{key_type}%")
      reg_type = case type 
                   when '1'; '(\d+)';
                   when 'a'; '([a-z]+)';
                   when 'A'; '([A-Z]+)';
                   else
                     abort "naming pattern type '#{type}' is unknown."
                   end
      reg.gsub!(reg_key_type,reg_type)
      key_type.replace(key)
    end
    reg = Regexp.new(reg)
    values = name.scan(reg).flatten
    return {} if values.nil? or values.size != keys.size
    keys.map!{|key| key.downcase}
    values.map!{|value|
      if value.match(/\d+/).nil?
        if value.size != 1
          abort "Naming pattern does not deal with port number with more than on letter. You supplied '#{value}'"
        end
        value = value.ord
        if ( 64 < value and value < 91 ) # [A-Z]
          value - 65
        elsif ( 96 < value and value < 123 ) # [a-z]
          value - 97
        else
          abort "Naming pattern port number is not within range = '#{value.chr}'"
        end
      else
        value.to_i
      end
    }
    Hash[keys.zip(values)]
  end

  # Decode naming pattern and return a string corresponding to the given hash containing keys and values within the naming pattern
  #
  # Vlan%VLANID% + {"vlanid"=>101}   =>    "Vlan101"
  # Po%CHANNELID% + {"channelid"=>2}   =>    "Po2"
  # Gi%LINECARD%/%PORT% + {"linecard"=>2, "port"=>7}   =>    "Gi2/7"
  # Te%LINECARD%/%PORT% + {"linecard"=>2, "port"=>7}   =>    "Te2/7"
  # Gi%STACK%/%LINECARD%/%PORT% + {"stack"=>2, "linecard"=>4, "port"=>5}   =>    "Gi2/4/5"
  # Te%STACK%/%LINECARD%/%PORT% + {"stack"=>2, "linecard"=>4, "port"=>5}   =>    "Te2/4/5"
  # Gi2/%LINECARD%/%PORT% + {"linecard"=>4, "port"=>5}   =>    "Gi2/4/5"
  # Te2/%LINECARD%/%PORT% + {"linecard"=>4, "port"=>5}   =>    "Te2/4/5"
  # %LINECARD:A%%PORT% + {"linecard"=>3, "port"=>5}    =>    "D5"
  # %LINECARD%%PORT:a% + {"linecard"=>3, "port"=>3}    =>    "3d"
  def self.decode(pattern,dict)
    keys = pattern.scan(/%([^%]+)%/).flatten
    return "" if keys.nil? or dict.size !=  keys.size
    name = pattern.dup
    keys.each do |key_type|
      key,type = key_type.split(/:([^:]+$)/)
      type = '1' if type.nil?
      value = dict[key.downcase]
      return "" if value.nil?
      reg_key_type = Regexp.new("%#{key_type}%")
      port = case type 
        when '1'; value.to_s;
        when 'a'; (value.to_i + 97).chr
        when 'A'; (value.to_i + 65).chr
        else
         abort "naming pattern type '#{type}' is unknown."
        end
      name.gsub!(reg_key_type,port)
    end
    name
  end
end
