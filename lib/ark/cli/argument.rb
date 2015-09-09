module Ark # :nodoc:
module CLI

# Represents an argument, either to the program itself or for options which
# take arguments.
class Argument

  # Raised when invalid argument syntax is given
  class ArgumentSyntaxError < ArgumentError
  end

  # Raised when an argument value is set improperly
  class ArgumentSetError < RuntimeError
  end

  # Parse an argument name and return an Argument object
  def self.parse(arg)
    arg = arg.to_s
    name = self.strip_arg(arg)
    if self.has_default?(arg)
      default = self.parse_default(arg)
      return Argument.new(name, default)
    elsif self.is_glob?(arg)
      return Argument.new(name, variad: true)
    else
      return Argument.new(name)
    end
  end

  # Strip any special syntax from a given argument name
  def self.strip_arg(arg)
    return arg.to_s[/^(\S+?)(:|\.\.\.|$)/, 1]
  end

  # Return +true+ if the given argument has a default value, like +'arg:defaultvalue'+
  def self.has_default?(arg)
    return !arg[/^\S+?:.+/].nil?
  end

  # Parse the default value from an arg with one
  def self.parse_default(arg)
    return arg[/^.+?:(.+)/, 1]
  end

  # Return +true+ if the given argument is a glob, like +'arg...'+
  def self.is_glob?(arg)
    return !arg[/\.\.\.$/].nil?
  end

  # Validate an option name. Names must be alphanumeric, and must begin with a
  # letter.
  def self.valid_name?(name)
    return !name.to_s[/^[[:alpha:]][[:alnum:]]+$/].nil?
  end

  # Initialize a new Argument object. +name+ must be alphanumeric and must begin
  # with a letter. If this argument is unfulfilled, +default+ will be returned
  # as its value, if default is non-nil. If +variad+ is true, then this argument
  # will act as a glob for all trailing args.
  def initialize(name, default=nil, variad: false)
    unless self.class.valid_name?(name)
      raise ArgumentSyntaxError, "Invalid argument name: #{name}"
    end
    @name = name.to_s
    @default = default
    @variad = variad
    if self.variadic?
      @value = []
    else
      @value = nil
    end
  end

  # Return the name of this Argument
  attr_reader :name

  # Return the value for this argument. The default value will be returned if
  # the argument is unset and the default is non-nil. If the argument is unset
  # and there is no default, return nil.
  def value
    if @value.nil?
      return @default
    else
      return @value
    end
  end

  # Push +val+ onto this argument. Only valid for variadic args. For normal
  # arguments, use #set instead.
  def push(val)
    unless self.variadic?
      raise ArgumentSetError, "Cannot push onto a normal argument. Use the #set method instead."
    end
    @value << val
  end

  # Set the value for this argument to +val+. Only valid for non-variadic
  # arguments. For variadic args, use #push instead.
  def set(val)
    if self.variadic?
      raise ArgumentSetError, "Cannot set the value of a glob, use the #push method instead."
    end
    @value = val
  end

  # Return true if this argument is a glob
  def variadic?
    return @variad
  end

  # Return true if this argument has a default value. Variadic arguments always
  # return true
  def has_default?
    return !@default.nil? || self.variadic?
  end

  # Return true if this argument has been given a value, or if it has a default
  # value. Variadic arguments will always return true, since they are never
  # required and always have a default value of +[]+
  def fulfilled?
    return !@value.nil? || self.has_default?
  end
end

end # module CLI
end # module Ark

