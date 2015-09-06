# ark-cli - a simple command line interface for Ruby
# Copyright 2015 Macquarie Sharpless <macquarie.sharpless@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'ark/utility'
include Ark::Log


module Ark # :nodoc:

# A library for handling options and arguments from the command line.
#
# Call #begin to define a new interface and parse the command line. See
# +README.md+ or +example/hello.rb+ for more information.

# Represents an option and stores the option's current state, as well as
# usage information.
class Option
  # Initialize a new Option instance
  # [+keys+] A list of names this option will be identified by
  # [+args+] A list of argument named this option will expect
  # [+desc+] A short description of this option
  def initialize(long, short=nil, args=nil, desc=nil)
    @long  = long
    @short = short
    @args  = args || []
    @vals  = []
    @flag  = false
    @count = 0
    @desc  = desc || ''
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

  # Return a count of how many arguments this option still expects
  def vals_needed()
    if self.flag?
      return 0
    else
      return @args.length - @vals.length
    end
  end

  # True if this option has received all the arguments it expects, or if this
  # option expects no arguments
  def full?
    return self.vals_needed == 0
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

  # Pass an argument +arg+ to this option
  def push(arg)
    @vals << arg
  end

  # Return the current value of this option
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

  # True if this option expects an argument. Opposite of #flag?
  def has_args?
    return @args.length > 0
  end

  # Return basic usage information: the option's names and arguments
  def header()
    if self.flag?
      args = ''
    else
      args = ' ' + @args.join(', ').upcase
    end
    short = @short ? " -#{@short}" : ''
    return "--#{@long}#{short}#{args}"
  end

  # Represent this option as a string
  def to_s()
    return "(#{self.header})"
  end
end


class CLI

  # Raised when the command line is malformed
  class SyntaxError < ArgumentError
  end

  # Convenience method for interface declarations. Yields the CLI instance and
  # then returns it after parsing. Equivalent to instantiating a CLI instance
  # with #new, modifying it, and then calling #parse
  #
  # +args+ is an array of strings, which defaults to ARGV
  def self.report(args=ARGV, &block)
    cli = self.new(args, &block)
    return cli.report
  end

  # Initialize a CLI instance.
  #
  # +args+ must be an array of strings, like ARGV
  def initialize(args, &block)
    self.rebuild(args, &block)
  end

  attr_reader :report

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

    tb.push '[OPTION'
    tb.add  '...' if @spec.has_options?
    tb.add  ']'

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
end

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
    return arg[/^(.+?)(\.\.\.$|_$|$)/, 1]
  end

  def optional?(arg)
    return !arg[/_$/].nil?
  end

  def variadic?(arg)
    return !arg[/\.\.\.$/].nil?
  end

  def parse_arg(arg, default: nil, last: false)
    stripped = strip(arg)
    @args << stripped
    if optional?(arg)
      @optional << stripped
    end
    unless default.nil?
      @defaults[stripped] = default
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

  def get_opts
    return @options
  end

  def is_variadic?
    return @variadic
  end

  def get_variad
    return @variad
  end

  def get_defaults
    return @defaults
  end

  # Get an Option object for the given option +name+
  def get_opt(name)
    name = name.to_sym
    if !@options.keys.member?(name)
      raise NoSuchOptionError, "Error, no such option: '#{name}'"
    end
    return @options[name]
  end

  def is_optional?(arg)
    @optional.member?(arg.to_s)
  end

  def has_default?(arg)
    @defaults.key?(arg.to_s)
  end

  def get_default(arg)
    @defaults[arg.to_s]
  end

  def has_args?
    @args.length > 0
  end

  def has_options?
    @options.values.uniq.length > 1
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
    @optional = []
    @defaults = {}

    input.flatten.each_with_index do |item, i|
      list_last = (input.length - (i + 1)) == 0
      if item.is_a?(Hash)
        item.each_with_index do |pair,ii|
          k = pair[0].to_s
          v = pair[1]
          hash_last = (item.length - (ii + 1)) == 0
          last = hash_last && list_last
          parse_arg(k, default: v, last: last)
        end
      else
        parse_arg(item, last: list_last)
      end
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

class Definition
end

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

end # module Ark

