module ARK # :nodoc:
module CLI

# The +Spec+ class defines the properties of an interface, namely its expected
# arguments and option definitions, as well as the program name and
# description. The +Spec+ instance forms the DSL used for interface declarations
# with the methods +name+, +desc+, +args+, and +opt+.
class Spec

  # Raised when a nonexistent option is received
  class NoSuchOptionError < ArgumentError
  end

  # Raised when there is a syntax error in the args declaration
  class ArgumentSyntaxError < ArgumentError
  end

  # Initialize a bare interface +Spec+
  def initialize()
    @arguments = {}
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

  # Get the name defined for this spec
  def get_name
    return @name
  end

  # Get the description defined for this spec
  def get_desc
    return @desc
  end

  # Get an array of argument names defined for this spec
  def get_args
    return @arguments
  end

  # Get version information defined for this spec
  def get_version
    return @version
  end

  # Return +true+ if this interface has any options defined for it
  def has_options?
    @options.values.uniq.length > 1
  end

  # Get a hash of any options defined on this spec
  def get_opts
    return @options
  end

  # Get an +Option+ object for the given option +name+
  def get_opt(name)
    name = name.to_s
    if !@options.keys.member?(name)
      raise NoSuchOptionError, "Error, no such option: '#{name}'"
    end
    return @options[name]
  end

  # Get an +Argument+ object for the given argument +name+
  def get_arg(name)
    name = name.to_s
    if !@arguments.keys.member?(name)
      raise NoSuchArgumentError, "Error, no such argument: '#{name}'"
    end
    return @arguments[name]
  end

  # Return +true+ if this interface is variadic
  def is_variadic?
    return @variadic
  end

  # Return the argument name of the variadic argument
  def get_variad
    return @variad
  end

  # Return +true+ if this interface has any arguments defined
  def has_args?
    @arguments.length > 0
  end

  # Specify general information about the program
  # [+name+] Name of the program
  # [+desc+] Short description of the program
  # [+args+] A list of named arguments
  # [+version+] Current version information for the program
  def header(name: nil, desc: nil, args: [], version: nil)
    self.name(name)
    self.desc(desc)
    self.args(args)
    self.version(version)
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
    @arguments = {}
    input.flatten.each_with_index do |item, i|
      item = item.to_s
      last = (input.length - (i + 1)) == 0
      arg  = Argument.parse(item)
      if arg.variadic?
        if !last
          raise ArgumentSyntaxError, "Variadic arguments must come last. Offending variad is '#{arg}'"
        else
          @variadic = true
          @variad = arg
        end
      end
      @arguments[arg.name] = arg
    end
  end

  # Set the version information for the program to +str+
  def version(str)
    @version = str.to_s if str
  end

  # Define an Option
  # [+keys+] A list of names for this option
  # [+args+] A list of arguments the option expects
  # [+desc+] A short description of the option, used to provide usage info
  def opt(long, short=nil, args: nil, desc: nil)
    long = long.to_s
    short = short.to_s if short
    args = [args] if args.is_a?(String)
    args.map! {|a| Argument.parse(a) } if args
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
end # module ARK

