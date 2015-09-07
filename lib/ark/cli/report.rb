module Ark # :nodoc:
module CLI

# Stores information parsed from the command line for later inspection
class Report
  # Initialize a bare +Report+ object
  def initialize()
    @args = []
    @named_args = {}
    @trailing_args = []
    @counts = {}
    @options = {}
  end
  
  # Return an array of all args parsed
  def args
    return @args
  end

  # Return a hash of named arguments
  def arg
    return @named_args
  end

  # Return an array of any arguments without names
  def trailing
    return @trailing_args
  end

  # Return a hash of options and their values
  def opt
    return @options
  end

  # Return a hash of options and their toggle counts
  def count
    return @counts
  end
end

end # module CLI
end # module Ark

