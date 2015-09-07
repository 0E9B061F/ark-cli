module Ark
module CLI

class Spec

  # Raised when a nonexistent option is received
  class NoSuchOptionError < ArgumentError
  end

  # Raised when there is a syntax error in the args declaration
  class ArgumentSyntaxError < ArgumentError
  end

  # Initialize a bare interface spec
  def initialize()
    @args = []
    @options = {}
    @variadic       = false
    @option_listing = false
    @trailing_error = false
  end

  # If true, the full option list will always be displayed in the usage info
  # header
  attr_reader :option_listing

  # If true, an error will be raised if trailing arguments are given
  attr_reader :trailing_error

  private

  def strip(arg)
    return arg[/^(\S+?)(:|\.\.\.|$)/, 1]
  end

  def defaulted?(arg)
    return !arg[/^\S+?:.+/].nil?
  end

  def parse_default(arg)
    return arg[/^.+?:(.+)/, 1]
  end

  def variadic?(arg)
    return !arg[/\.\.\.$/].nil?
  end

  def parse_arg(arg, default: nil, last: false)
    stripped = strip(arg)
    @args << stripped
    if defaulted?(arg)
      @defaults[stripped] = parse_default(arg)
    end
    if variadic?(arg)
      if last
        @variadic = true
        @variad = stripped
      else
        raise ArgumentSyntaxError,
        "Variadic arguments must come last. Offending variad is '#{arg}'"
      end
    end
  end

  public

  def get_name
    return @name
  end

  def get_desc
    return @desc
  end

  def get_args
    return @args
  end

  def has_options?
    @options.values.uniq.length > 1
  end

  def get_opts
    return @options
  end

  # Get an Option object for the given option +name+
  def get_opt(name)
    name = name.to_sym
    if !@options.keys.member?(name)
      raise NoSuchOptionError, "Error, no such option: '#{name}'"
    end
    return @options[name]
  end

  def is_variadic?
    return @variadic
  end

  def get_variad
    return @variad
  end

  def has_default?(arg)
    @defaults.key?(arg.to_s)
  end

  def get_defaults
    return @defaults
  end

  def get_default(arg)
    @defaults[arg.to_s]
  end

  def has_args?
    @args.length > 0
  end

  # Specify general information about the program
  # [+name+] Name of the program
  # [+desc+] Short description of the program
  # [+args+] A list of named arguments
  def header(name: nil, desc: nil, args: [])
    self.name(name)
    self.desc(desc)
    self.args(args)
  end

  # Set the name of the program to +str+
  def name(str)
    @name = str.to_s if str
  end

  # Set the description of the program to +str+
  def desc(str)
    @desc = str.to_s if str
  end

  # Define what arguments the program will accept
  def args(*input)
    @args = []
    @defaults = {}

    input.flatten.each_with_index do |item, i|
      last = (input.length - (i + 1)) == 0
      parse_arg(item, last: last)
    end

    @refargs = @args.clone
  end

  # Define an Option
  # [+keys+] A list of names for this option
  # [+args+] A list of arguments the option expects
  # [+desc+] A short description of the option, used to provide usage info
  def opt(long, short=nil, args: nil, desc: nil)
    long = long.to_sym
    short = short.to_sym if short
    args = [args] if args.is_a?(String)
    args.map!(&:to_sym) if args
    o = Option.new(long, short, args, desc)
    @options[long] = o
    @options[short] = o if short
  end

  # Force the full option list display in the usage info, no matter how many
  # options the program has
  def force_option_list()
    @option_list = true
  end

  # The parser will raise an error on finding trailing arguments (default
  # behavior is to ignore and stuff the trailing args into Report.trailing_args)
  def raise_on_trailing()
    @trailing_error = true
  end

end

end # module CLI
end # module Ark

