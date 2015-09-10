module Ark # :nodoc:
module CLI

# Stores information parsed from the command line for later inspection
class Report
  # Initialize a bare +Report+ object
  def initialize(args, named, trailing, options, counts)
    @args     = args
    @named    = named
    @trailing = trailing
    @options  = options
    @counts   = counts
  end
  
  # Return an array of all args parsed
  def args
    return @args
  end

  # Get an argument by +name+
  def arg(name)
    return @named[name.to_s]
  end

  # Return an array of any arguments without names
  def trailing
    return @trailing
  end

  # Get a hash of all options and their values
  def opts
    return @options
  end

  # Get the value of an option by +name+
  def opt(name)
    return @options[name.to_s]
  end

  # Get the toggle count for an option by +name+
  def count(name)
    return @counts[name.to_s]
  end
end

end # module CLI
end # module Ark

