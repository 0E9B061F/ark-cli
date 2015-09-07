module Ark # :nodoc:
module CLI

# Main class for ark-cli. Defines a +Spec+, parses the command line and returns
# +Report+ objects.
class Interface

  # Raised when the command line is malformed
  class SyntaxError < ArgumentError
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
    @spec.opt :help, :h, desc: "Print usage information"
    self.parse
  end

  # Parse the command line
  def parse()
    taking_options = true
    last_opt = nil
    refargs = @spec.get_args.clone

    @report = Report.new()

    @input.each do |word|
      dbg "Parsing '#{word}'"
      if last_opt && last_opt.has_args? && !last_opt.full?
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
            end
          end
        else
          dbg "Parsed output arg", 1
          taking_options = false
          @report.args << word
          key = refargs.shift
          if key
            if key == @spec.get_variad
              @report.arg[key] = []
              @report.arg[key] << word
            else
              @report.arg[key] = word
            end
          elsif @spec.is_variadic?
            @report.arg[@spec.get_variad] << word
          else
            @report.trailing << word
          end
        end
      end
    end
    @spec.get_opts.each do |name, opt|
      @report.opt[name] = opt.value
      @report.count[name] = opt.count
    end
    @spec.get_args.each do |name|
      if @report.arg[name].nil?
        if @spec.has_default?(name)
          @report.arg[name] = @spec.get_default(name)
          @report.args << @report.arg[name]
        end
      end
    end
    if @report.opt[:help]
      self.print_usage()
    end
  end

  # Construct usage information
  def usage()
    tb = TextBuilder.new()

    tb.next 'USAGE:'
    tb.push @spec.get_name if @spec.get_name

    if @spec.get_opts.values.uniq.length < 5 || @spec.option_listing
      @spec.get_opts.values.uniq.each do |opt|
        tb.push "[#{opt.header}]"
      end
    else
      tb.push '[OPTION...]'
    end

    if @spec.has_args?
      if @spec.is_variadic?
        singles = @spec.get_args[0..-2].map do |a|
          if @spec.has_default?(a)
            a = "[#{a}]"
          end
          a.upcase
        end
        tb.push singles
        v = @spec.get_args.last.upcase
        tb.push "[#{v}1 #{v}2...]"
      else
        argmap = @spec.get_args.map do |a|
          if @spec.has_default?(a)
            a = "[#{a}]"
          end
          a.upcase
        end
        tb.push argmap
      end
    end

    tb.wrap indent: 7, indent_after: true, segments: true

    if @spec.get_desc
      tb.skip @spec.get_desc
      tb.wrap(indent: 4)
    end

    tb.skip 'OPTIONS:'
    tb.skip

    @spec.get_opts.values.uniq.each do |opt|
      tb.indent 4
      tb.push opt.header
      if opt.desc
        tb.next
        tb.indent 8
        tb.push opt.desc
      end
      tb.skip
    end

    return tb.print
  end

  # Print usage information and exit
  def print_usage()
    puts self.usage
    exit 0
  end

end # class Interface

end # module CLI
end # module Ark

