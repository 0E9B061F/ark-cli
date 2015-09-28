module ARK # :nodoc:
module CLI

# Represents an option and stores the option's current state, as well as
# usage information.
class Option

  # Initialize a new Option instance
  # [+keys+] A list of names this option will be identified by
  # [+args+] A list of argument named this option will expect
  # [+desc+] A short description of this option
  def initialize(long, short=nil, args=nil, desc=nil)
    @long      = long
    @short     = short
    @args      = args || []
    @flag      = false
    @count     = 0
    @desc      = desc || ''
    @arg_index = 0
  end

  # A count of how many times this option has been given on the command line.
  # Useful for flags that might be specified repeatedly, like +-vvv+ to raise
  # verbosity three times.
  attr_reader :count

  # A short description of the option, if given
  attr_reader :desc

  # Long name for this option
  attr_reader :long

  # Short name for this option
  attr_reader :short

  # Return the number of arguments this option expects
  def arity()
    return @args.length
  end

  # True if this option has received all the arguments it expects, or if this
  # option expects no arguments
  def full?
    if self.flag?
      return true
    else
      return (@args.length - @arg_index) < 1
    end
  end

  # True if this option expects no arguments; opposite of #has_args?
  def flag?
    return @args.empty?
  end

  # Toggle this option to the true state and increment the toggle count. Only
  # valid for options which expect no argument (flags). Attempting to toggle
  # a option with expected arguments will raise an error.
  def toggle()
    if self.flag?
      @count += 1
      @flag = true
    else
      raise StandardError, "Tried to toggle an option which expects an argument"
    end
  end

  # Pass an argument to this option
  def push(val)
    arg = @args[@arg_index]
    @arg_index += 1
    arg.set(val)
  end

  # Return the current value of this option
  def value()
    if self.flag?
      return @flag
    else
      vals = @args.map {|a| a.value }
      vals = vals.first if vals.length == 1
      return vals
    end
  end

  # True if this option expects an argument. Opposite of #flag?
  def has_args?
    return @args.length > 0
  end

  # Return basic usage information: the option's names and arguments
  def header()
    if self.flag?
      args = ''
    else
      args = ' ' + @args.map {|a| a.name }.join(', ').upcase
    end
    short = @short ? "-#{@short} " : ''
    return "#{short}--#{@long}#{args}"
  end

  # Represent this option as a string
  def to_s()
    return "(#{self.header})"
  end
end


end # module CLI
end # module ARK

