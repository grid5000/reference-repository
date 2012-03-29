require 'optparse'
require 'logger'

class CmdLineScript
  def initialize
    @version = "0.1"
  end
  def sanitize(str)
    str.strip.downcase.gsub(/\s+/,"-")
  end
  def parse!(args,params=[])
    args.push("-h") if args.empty?
    # Save the user options
    user_args = args.dup
    args.clear
    @parsing_args = args
    @prev_parsing_args_size = @parsing_args.size
    @min_opt_index = 0
    @options_loaded = []
    
    @opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(ENV["_"])} [options]"      
      opts.on_tail("--version", "Display the version.") do |v|
        puts @version
        exit(0)
      end
      opts.on_tail("-h", "--help", "You are looking at it.") do
        puts opts.help
        exit(0)
      end
    end

    @options = {}
    if block_given?
      yield
    elsif params.is_a? Array
      until params.empty?
        k = params.shift
        v = params.shift
        add_option k,v
      end
    else
      fail "This method must receive a block or an Array "
    end
    add_option :logger

    # Merge first options with user's options (priority to user options)
    merge_options user_args
    
    @prev_parsing_args_size = @parsing_args.size
    
    @opt_parser.parse!(@parsing_args)
  end
  def add_option(opt_sym,opt_dft=nil)
    current_parsing_args_size = @parsing_args.size
    parser_opts_nb = @prev_parsing_args_size - current_parsing_args_size
    @min_opt_index -= parser_opts_nb

    unless @options_loaded.include? opt_sym
      opt_str = opt_sym_to_str opt_sym
      dft_aft = send("option_#{opt_sym.to_s}",opt_sym,opt_str,opt_dft)
      opt_dft = dft_aft unless dft_aft.nil? or dft_aft.kind_of? OptionParser
      default_args opt_str, opt_dft
      @options_loaded.push opt_sym
    end
    @prev_parsing_args_size = @parsing_args.size
  end

  # Find the index of a given option within the arguments that are being parsed
  # Return -1 if the argument is not found.
  def option_index(opt)
    @parsing_args.each_with_index{|o,idx|
      if o == opt
        return idx
      end
    }
    return -1
  end

  def opt_sym_to_str(opt_sym)
    "--"+opt_sym.to_s.gsub(/_/,'-')
  end
  def opt_str_to_sym(opt_str)
    opt_str.gsub(/^--/,"").gsub(/-/,"_").to_sym
  end
  # Set the argument for an option.
  # If the option has already been parsed, set its value,
  # Otherwise, set its value within the parsing arguments.
  def set_arg(opt,arg,params={})
    params[:force] = true unless params.has_key? :force
    #puts "opt = #{opt}"
    opt_idx = option_index(opt.to_s)
    if opt_idx > -1 and params[:force]
      @parsing_args[opt_idx+1].replace(arg)
    else
      opt_sym = opt_str_to_sym opt
      unless @options.has_key? opt_sym and !params[:force]
        @parsing_args.concat([opt,arg])
      end
    end
  end
  def get_arg(opt_sym)
    opt_str = opt_sym_to_str opt_sym
    opt_idx = option_index(opt_str.to_s)
    (opt_idx > -1 ) ? @parsing_args[opt_idx+1] : nil
  end
  # Set the default option argument.
  # If the user issued an argument, leave that as the default argument for the option
  # The option and argument are both appended at the end of argument array, even if they were already within the array.
  # This make sure options and arguments are parsed in the order they are declared, not in the order user supplied them.
  def default_args(opt,arg)
    opt_idx = option_index(opt.to_s)
    #~ puts "opt = #{opt} opt_idx=#{opt_idx} @min_opt_index = #{@min_opt_index}"
    
    if opt_idx < 0
      # If option not found yet, place it at the min_index position
      insert_arg(@min_opt_index,opt,arg)
      @min_opt_index += 2      
    else
      # If option found, it may be before or after the min_index
      if opt_idx < @min_opt_index
        # if before the min_index, do nothing since this option was already computed
        arg.replace @parsing_args[opt_idx+1]
      elsif  opt_idx == @min_opt_index
        # if equal to min_index, unshift the min_index value
        @min_opt_index += 2
        arg.replace @parsing_args[opt_idx+1]
      else
        # if after the min_index, remove it and insert it at the min_index position
        opt.replace(@parsing_args.slice!(opt_idx))
        arg.replace(@parsing_args.slice!(opt_idx))
        insert_arg(@min_opt_index,opt,arg)
        @min_opt_index += 2
      end
    end
  end
  def insert_arg(index,opt,arg)
    @parsing_args.insert(index,arg)
    @parsing_args.insert(index,opt)
  end
  def merge_options(before)
    help = []
    until before.empty?
      opt = before.shift
      unless /^-/.match(opt).nil?
        if opt == "--help" or opt == "-h" or opt == "--version"
          help.push opt 
        else
          set_arg opt,before.shift
        end
      end
    end
    @parsing_args.concat(help)
  end

  # Mandatory options (as an example too)
  def option_logger(opt_sym,opt_str,opt_dft)
    opt_dft ||= "stdout:info"
    @opt_parser.on("#{opt_str}=", "The logger. Can be [none, path:level]. [default=#{opt_dft}].") do |log|
      levels = {:fatal=>Logger::FATAL,
        :error=>Logger::ERROR,
        :warn=>Logger::WARN,
        :info=>Logger::INFO,
        :debug=>Logger::DEBUG
      }
      logger = nil
      if log.empty? or log == "none"
        logger = Logger.new("/dev/null")
        logger.level = levels[:fatal]
      else
        type,level = log.split(/:/,2)
        logger = case type
        when "stdout";Logger.new(STDOUT)
        when "stderr";Logger.new(STDERR)
        else;Logger.new(File.expand_path(type))
        end
        level = (level || "info").to_sym
        level = :info unless levels.has_key? level
        logger.level = levels[level] 
      end
      @options[opt_sym] = logger unless logger.nil?
    end
    opt_dft
  end
end
