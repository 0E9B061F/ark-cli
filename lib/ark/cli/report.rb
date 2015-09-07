module Ark
module CLI

class Report
  def initialize()
    @args = []
    @named_args = {}
    @trailing_args = []
    @counts = {}
    @options = {}
  end
  
  def args
    return @args
  end
  def arg
    return @named_args
  end
  def trailing
    return @trailing_args
  end
  def opt
    return @options
  end
  def count
    return @counts
  end
end

end # module CLI
end # module Ark

