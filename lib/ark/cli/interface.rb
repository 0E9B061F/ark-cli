module ARK # :nodoc:
module CLI

# Main class for ark-cli. Defines a +Spec+, parses the command line and returns
# +Report+ objects.
class Interface

  # Raised when the command line is malformed
  class SyntaxError < ArgumentError
  end

  # Raised when a required argument is not given
  class InterfaceError < ArgumentError
  end

  # :call-seq:
  # rebuild(input=ARGV) { |spec| ... } => Interface
  #
  # Initialize an Interface instance.
  #
  # +args+ must be an array of strings, like ARGV
  def initialize(args, &block)
    self.rebuild(args, &block)
  end

  # The +Report+ object for this interface, for inspecting information parsed
  # from the command line.
  attr_reader :report

  # Rebuild the interface with a new spec and args
  def rebuild(input=ARGV, &block)
    @input = input
    @spec = Spec.new
    yield @spec
    @spec.opt :help, :h, desc: "Print usage information and exit"
    if @spec.get_version
      @spec.opt :version, :V, desc: "Print version information and exit"
    end
    self.parse
  end

  # Parse the command line
  def parse()
    taking_options = true
    last_opt = nil

    args = []
    trailing = []
    named = {}
    options = {}
    counts = {}
    arg_index = 0

    @input.each do |word|
      dbg "Parsing '#{word}'"
      if word == '--'
        taking_options = false
      elsif last_opt && last_opt.has_args? && !last_opt.full? && taking_options
        dbg "Got argument '#{word}' for '#{last_opt}'", 1
        last_opt.push(word)
      else
        if word[/^-/] && taking_options
          if word[/^-[^-]/]
            dbg "Identified short option(s)", 1
            shorts = word[/[^-]+$/].split('')
            shorts.each_with_index do |short, i|
              last_short = i == (shorts.length - 1)
              opt = @spec.get_opt(short)
              last_opt = opt
              if opt.has_args? && shorts.length > 1 && !last_short
                raise SyntaxError, "Error: -#{short} in compound option '#{word}' expects an argument"
              elsif opt.flag?
                opt.toggle()
                dbg "Toggled flag '#{opt}'", 1
              else
                opt.increment
              end
            end
          elsif word[/^--/]
            dbg "Identified long option", 1
            key = word[/[^-]+$/]
            opt = @spec.get_opt(key)
            last_opt = opt
            if opt.flag?
              opt.toggle()
              dbg "Toggled #{opt}", 1
            else
              opt.increment
            end
          end
        else
          dbg "Parsed output arg", 1
          taking_options = false
          arg = @spec.get_args.values[arg_index]
          arg_index += 1
          if arg && !arg.variadic?
            arg.set(word)
          elsif @spec.is_variadic?
            @spec.get_variad.push(word)
          else
            trailing << word
          end
        end
      end
    end

    @spec.get_opts.each do |name, opt|
      options[name] = opt.value
      counts[name]  = opt.count
    end

    @spec.get_args.each do |name, arg|
      args << arg.value
      named[name] = arg.value
    end
    args.flatten!
    args += trailing

    @report = Report.new(args, named, trailing, options, counts)

    if @report.opt(:help)
      self.print_usage
    end

    if @report.opt(:version)
      self.print_version
    end

    unless @spec.get_args.values.all? {|arg| arg.fulfilled? }
      raise InterfaceError, "Required argument '#{name.upcase}' was not given."
    end

    if @spec.trailing_error && !@report.trailing.empty?
      raise InterfaceError, "Error: got trailing argument(s): #{trailing.join(', ')}"
    end
  end

  # Construct usage information
  def usage()
    tb = TextBuilder.new()

    tb.next('USAGE:')
    tb.push(@spec.get_name) if @spec.get_name

    if @spec.get_opts.values.uniq.length < 5 || @spec.option_listing
      @spec.get_opts.values.uniq.each do |opt|
        tb.push("[#{opt.header}]")
      end
    else
      tb.push('[OPTION...]')
    end

    if @spec.has_args?
      if @spec.is_variadic?
        singles = @spec.get_args.values[0..-2].map do |a|
          name = a.name
          if a.has_default?
            name = "[#{name}]"
          end
          name.upcase
        end
        tb.push(singles)
        v = @spec.get_variad.name.upcase
        tb.push("[#{v}1 #{v}2...]")
      else
        argmap = @spec.get_args.values.map do |a|
          name = a.name
          if a.has_default?
            name = "[#{name}]"
          end
          name.upcase
        end
        tb.push(argmap)
      end
    end

    tb.wrap(indent: 7, indent_after: true, segments: true)

    if @spec.get_desc
      tb.skip(@spec.get_desc)
      tb.wrap(indent: 4)
    end

    tb.skip('OPTIONS:').skip

    @spec.get_opts.values.uniq.each do |opt|
      tb.indent(4).push(opt.header)
      if opt.desc
        tb.next.indent(8).push(opt.desc)
      end
      tb.skip
    end

    return tb.to_s
  end

  # Print usage information and exit
  def print_usage
    puts self.usage
    exit 0
  end

  def print_version
    puts @spec.get_version
    exit 0
  end

end # class Interface

end # module CLI
end # module ARK

