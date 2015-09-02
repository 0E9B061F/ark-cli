require 'ark/utility'
include Ark::Log

module Ark

class CLI

  # Raised when a nonexistant option is received
  class NoSuchOptionError < ArgumentError
  end

  # Raised when the command line is malformed
  class SyntaxError < ArgumentError
  end

  class Option
    def initialize(keys, args=nil, desc=nil)
      @keys  = keys
      @args  = args || []
      @vals  = []
      @flag  = false
      @count = 0
      @desc  = desc || ''
    end
    attr_reader :count

    def arity()
      return @args.length
    end

    def vals_needed()
      if self.flag?
        return 0
      else
        return @args.length - @vals.length
      end
    end

    def full?
      return self.vals_needed == 0
    end

    def flag?
      return @args.empty?
    end

    # 'Toggling' a flag only turns it on
    # The number of toggles is held in @count
    def toggle()
      if self.flag?
        @count += 1
        @flag = true
      else
        raise StandardError, "Tried to toggle an option which expects an argument"
      end
    end

    def push(arg)
      @vals << arg
    end

    def value()
      if self.flag?
        return @flag
      else
        if self.full? && @vals.length == 1
          return @vals[0]
        elsif self.full?
          return @vals
        else
          return nil
        end
      end
    end

    def has_args?
      return @args.length > 0
    end

    def header()
      if self.flag?
        args = ''
      else
        args = ' ' + @args.join(', ').upcase
      end
      keys = @keys.sort {|a,b| a.length <=> b.length }
      keys = keys.map {|k| k.length > 1 ? "--#{k}" : "-#{k}" }
      keys = keys.join(' ')
      return keys + args
    end

    def to_s()
      return "(#{self.header})"
    end

    def usage()
      self.header + "\n" + '        ' + @desc
    end
  end

  def self.begin(args=ARGV, &block)
    cli = self.new(args)
    block[cli]
    cli.parse()
    if cli[:help]
      cli.print_help()
      exit 0
    else
      return cli
    end
  end

  def initialize(args)
    @args = args
    @output_args = []
    @scriptargs = []
    @named_args = {}
    @options = {}

    self.opt :help, :h, desc: "Print usage information"
  end

  def parse()
    taking_options = true
    last_opt = nil

    @args.each do |word|
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
              opt = self.get_opt(short)
              last_opt = opt
              if opt.has_args? && shorts.length > 1 && !last_short
                raise SyntaxError, "Error: compound option '#{word}' expected an argument"
              elsif opt.flag?
                opt.toggle()
                dbg "Toggled flag '#{opt}'", 1
              end
            end
          elsif word[/^--/]
            dbg "Identified long option", 1
            key = word[/[^-]+$/]
            opt = self.get_opt(key)
            last_opt = opt
            if opt.flag?
              opt.toggle()
              dbg "Toggled #{opt}", 1
            end
          end
        else
          dbg "Parsed output arg", 1
          taking_options = false
          @output_args << word
          key = @scriptargs.shift
          @named_args[key] = word if key
        end
      end
    end

  end

  def opt(*keys, **parameters)
    keys.map! {|k| k.to_sym }
    args = parameters[:args]
    desc = parameters[:desc]
    o = Option.new(keys, args, desc)
    keys.each {|k| @options[k] = o }
  end

  def args()
    return @output_args
  end

  def arg(key)
    return @named_args[key]
  end

  def get_opt(key)
    key = key.to_sym
    if !@options.keys.member?(key)
      raise NoSuchOptionError, "Error, no such option: '#{key}'"
    end
    return @options[key]
  end

  def [](key)
    return self.get_opt(key).value
  end

  # Get the toggle count of a flag
  def count(key)
    return self.get_opt(key).count
  end

  def header(**fields)
    @scriptname = fields[:name]
    @desc = fields[:desc]
    @scriptargs = fields[:args].map(&:to_sym)
  end

  def print_help()
    if @scriptname || @desc
      if @scriptname
        options = ''
        args =''
        if @options.length == 1
          options = " [OPTION]"
        elsif @options.length > 1
          options = " [OPTION...]"
        end
        if @scriptargs
          args = ' ' + @scriptargs
        end
        puts "#{@scriptname}#{options}#{args}"
      end
      if @desc
        puts '    ' + @desc
      end
      if @options.length > 0
        puts
        puts 'OPTIONS:'
        puts
      end
    end
    @options.values.uniq.each do |opt|
      puts '    ' + opt.usage
      puts
    end
  end

end

end

