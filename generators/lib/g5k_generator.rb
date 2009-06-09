require 'resolv'

module G5K
  SITES = %w{rennes grenoble bordeaux toulouse sophia orsay nancy lille lyon}
  
  class Tree < Hash
    attr_reader :contents, :path
    def write(repository, &block)
      self[:uid] ||= ""
      @contents = {}
      @path = File.join(repository, self[:uid]+".json")
      self.each do |key, value|
        if value.is_a? Folder
          value.write(File.join(repository, self[:uid], key.to_s), &block)
          @path = File.join(repository, self[:uid], self[:uid]+".json")
        else
          @contents.merge!(key => value)
        end
      end
      if !@contents.empty? && !@contents[:uid].empty?
        yield self
      end
    end
    
    def valid?
      true
      # we could do sthg like: Load(type.class).new(hash_values).valid?
    end
  end
  class Folder < Array
    attr_reader :path
    def write(repository, &block)
      @path = repository
      self.each do |v| 
        v.write(repository, &block)
      end
      yield self
    end
    def valid?
      true
    end
  end
  class Link < Struct.new(:uid, :refer_to)
    attr_reader :from, :path
  
    def write(repository)
      @from, @path = [refer_to, File.join(repository, "#{uid}.json")]
      yield self
    end
    def valid?
      true
    end
  end

class ReferenceGenerator  
  attr_reader :data
  attr_reader :config
  attr_reader :input
  
  def method_missing(method, *args)
    @context.recursive_merge!(method.to_sym => args.first)
  end
  
  def dns_lookup(network_address)
    Resolv.getaddress(network_address)
  end
  
  #
  # usage:
  #   lookup('nancy', 'nodes', 'paramount-1', 'property_name')
  # or
  #   lookup('nancy', 'nodes') { |result| result['paramount-1']['property_name'] }
  # or
  #   lookup('nancy') { |result| result['nodes']['paramount-1']['property_name'] }
  # 
  # assuming you passed a <tt>nancy.yaml</tt> file to the generator
  # Be careful with null values!
  #
  def lookup(filename, *keys, &block)
    if config.has_key?(filename)
      result = config[filename]
      if !keys.empty?
        while !keys.empty? do
          result = result[keys.shift]
          break if result.nil?
        end
      end  
      if block
        block.call(result) 
      else
        result
      end
    else
      nil
    end
  end
  # This doesn't work with Ruby < 1.8.7. Replaced by a call to build_context (see below).
  #
  # %w{site cluster environment node service}.each do |method|
  #   define_method(method) do |uid, *options, &block|
  #     key = method.pluralize.to_sym
  #     uid = uid.to_s
  #     options = options.first || Hash.new
  #     old_context = @context
  #     @context[key] ||= G5K::Folder.new
  #     if options.has_key? :refer_to
  #       @context[key] << G5K::Link.new(uid, options[:refer_to])
  #     else    
  #       # if the same object already exists, we return it for completion/modification
  #       if (same_trees = @context[key].select{|tree| tree[:uid] == uid}).size > 0
  #         @context = same_trees.first
  #       else
  #         @context[key] << G5K::Tree.new.replace({:uid => uid, :type => method})
  #         @context = @context[key].last
  #       end
  #       block.call(uid) if block
  #     end
  #     @context = old_context
  #   end
  # end
  
  def site(uid, *options, &block)
    build_context(:sites, uid, *options, &block)
  end
  def cluster(uid, *options, &block)
    build_context(:clusters, uid, *options, &block)
  end
  def environment(uid, *options, &block)
    build_context(:environments, uid, *options, &block)
  end
  def node(uid, *options, &block)
    build_context(:nodes, uid, *options, &block)
  end
  def service(uid, *options, &block)
    build_context(:services, uid, *options, &block)
  end
  def build_context(key, uid, *options, &block)
    type = key.to_s.chop
    uid = uid.to_s
    options = options.first || Hash.new
    old_context = @context
    @context[key] ||= G5K::Folder.new
    if options.has_key? :refer_to
      @context[key] << G5K::Link.new(uid, options[:refer_to])
    else    
      # if the same object already exists, we return it for completion/modification
      if (same_trees = @context[key].select{|tree| tree[:uid] == uid}).size > 0
        @context = same_trees.first
      else
        @context[key] << G5K::Tree.new.replace({:uid => uid, :type => type})
        @context = @context[key].last
      end
      block.call(uid) if block
    end
    @context = old_context
  end
  
  # Initializes a new generator that will generate data files in a hierachical way. 
  # The root of the tree will be named with the value of <tt>data_description[:uid]</tt>.
  def initialize(data_description = {:uid => ""}, options = {:input => {}, :config => {}})
    @input = options[:input] || raise(ArgumentError, "INPUT cannot be null.")
    @config = options[:config] || {}
    @data = G5K::Tree.new.replace(data_description)
    @context = @data
  end
  
  def generate
    input.each do |filename, content|
      eval(content)
    end
    @data
  end
  
  def write(repository, options = {:simulate => false})
    things_to_create = []
    @data.write("/") do |thing_to_create|
      things_to_create << thing_to_create if thing_to_create.valid?
    end
    groups = things_to_create.group_by{|thing| thing.class}
    groups.has_key?(G5K::Folder) and groups[G5K::Folder].each do |folder|
      full_path = File.join(repository, folder.path)
      unless File.exists?(full_path)
        puts "Directory to be written = \t#{full_path}"
        FileUtils.mkdir_p(full_path) unless options[:simulate]
      end
    end
    groups.has_key?(G5K::Tree) and groups[G5K::Tree].each do |file|
      full_path = File.join(repository, file.path)
      new_content = JSON.pretty_generate(file.contents)
      existing_content = File.exists?(full_path) ? File.open(full_path, "r").read : ""
      if new_content.hash != existing_content.hash
        puts "File to be written      = \t#{full_path}"
        File.open(full_path, "w+"){ |f| f << new_content  } unless options[:simulate]
      end
    end
    groups.has_key?(G5K::Link) and groups[G5K::Link].each do |link|      
      FileUtils.cd(repository) do |dir|
        to = File.join(".", link.path)
        from = File.join([".."]*(to.count(File::SEPARATOR)-1), "#{link.from}.json")
        unless File.exists?(to)
          puts "Symbolic link to be written = \t#{to} -> #{from}"
          FileUtils.ln_s(from, to, :force => true) unless options[:simulate]
        end
      end
    end  
  end
  
end
end