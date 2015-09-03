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
class CLI

  # Raised when a nonexistent option is received
  class NoSuchOptionError < ArgumentError
  end

  # Raised when the command line is malformed
  class SyntaxError < ArgumentError
  end

  # Represents an option and stores the option's current state, as well as
  # usage information.
  class Option
    # Initialize a new Option instance
    # [+keys+] A list of names this option will be identified by
    # [+args+] A list of argument named this option will expect
    # [+desc+] A short description of this option
    def initialize(keys, args=nil, desc=nil)
      @keys  = keys
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
      keys = @keys.sort {|a,b| a.length <=> b.length }
      keys = keys.map {|k| k.length > 1 ? "--#{k}" : "-#{k}" }
      keys = keys.join(' ')
      return keys + args
    end

    # Represent this option as a string
    def to_s()
      return "(#{self.header})"
    end
  end

  # Convenience method for interface declarations. Yields the CLI instance and
  # then returns it after parsing. Equivalent to instantiating a CLI instance
  # with #new, modifying it, and then calling #parse
  #
  # +args+ is an array of strings, which defaults to ARGV
  def self.begin(args=ARGV, &block)
    cli = self.new(args)
    yield cli
    cli.parse()
    if cli[:help]
      cli.print_help()
      exit 0
    else
      return cli
    end
  end

  # Initialize a CLI instance.
  #
  # +args+ must be an array of strings, like ARGV
  def initialize(args)
    @args = args
    @output_args = []
    @scriptargs = []
    @refargs = []
    @named_args = {}
    @options = {}
    @variadic = false
    @variad = nil
    @scriptname = nil
    @desc = nil

    self.opt :help, :h, desc: "Print usage information"
  end

  # Parse the command line
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
          if key
            if key == @variad
              @named_args[key] = []
              @named_args[key] << word
            else
              @named_args[key] = word
            end
          elsif @variadic
            @named_args[@variad] << word
          end
        end
      end
    end

  end

  # Define an Option
  # [+keys+] A list of names for this option
  # [+args+] A list of arguments the option expects
  # [+desc+] A short description of the option, used to provide usage info
  def opt(*keys, args: nil, desc: nil)
    raise ArgumentError, "An option must have at least one name" if keys.empty?
    keys.map!(&:to_sym)
    args.map!(&:to_sym) if args
    o = Option.new(keys, args, desc)
    keys.each {|k| @options[k] = o }
  end

  # Return all command line arguments
  def args()
    return @output_args
  end

  # Return the value of the named argument +name+
  def arg(name)
    return @named_args[name.to_sym]
  end

  # Get an Option object for the given option +name+
  def get_opt(name)
    name = name.to_sym
    if !@options.keys.member?(name)
      raise NoSuchOptionError, "Error, no such option: '#{name}'"
    end
    return @options[name]
  end

  # Get the value of a given option by +name+
  def [](name)
    return self.get_opt(name).value
  end

  # Get the toggle count of a flag by +name+
  def count(name)
    return self.get_opt(name).count
  end

  # Specify general information about the program
  # [+name+] Name of the program
  # [+desc+] Short description of the program
  # [+args+] A list of named arguments
  def header(name: nil, desc: nil, args: [])
    @scriptname = name
    @desc = desc
    @scriptargs = args.map(&:to_sym)
    if @scriptargs.last == :*
      if @scriptargs.length > 1
        @variadic = true
        @scriptargs.pop
        @refargs = @scriptargs.clone
        @variad = @scriptargs.last
      else
        @scriptargs = []
      end
    else
      @refargs = @scriptargs.clone
    end
  end

  # Print usage information
  def print_help()
    tb = TextBuilder.new()

    tb.push @scriptname || 'Usage:'

    if @options.length > 0
      tb.push '[OPTION'
      tb.add  '...' if @options.values.uniq.length > 1
      tb.add  ']'
    end

    if !@refargs.empty?
      if @variadic
        singles = @refargs[0..-2].map(&:upcase)
        tb.push singles
        v = @variad.upcase
        tb.push "#{v}1 #{v}2..."
      else
        tb.push @refargs.map(&:upcase)
      end
    end

    if @desc
      tb.next @desc
      tb.wrap(indent: 4)
    end

    tb.skip 'OPTIONS:'
    tb.skip

    @options.values.uniq.each do |opt|
      tb.indent 4
      tb.push opt.header
      if opt.desc
        tb.next
        tb.indent 8
        tb.push opt.desc
      end
      tb.skip
    end

    puts tb.print
  end

end

end

