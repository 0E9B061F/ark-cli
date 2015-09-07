# ark-cli

[![Gem Version](https://badge.fury.io/rb/ark-cli.svg)](http://badge.fury.io/rb/ark-cli)

__ark-cli__ is a Ruby library for handling command line options and
arguments. See below for basic usage. Full documentation can be found at
http://www.rubydoc.info/github/grimheart/ark-cli



## Declaring an interface

The usual way to use ark-cli is to call `Ark::CLI.report`. This convenience
method builds a new interface and returns a `Report` object for inspection.

```ruby
require 'ark/cli'

# Declare an interface and parse the command line
# Returns a Report instance for inspection as `r`
r = Ark::CLI.report do |s|
  s.name 'example'
  s.args 'host', 'path'
  s.desc "An example demonstrating usage of ark-cli"

  s.opt :verbose, :v,
  desc: "Increase verbosity"

  s.opt :port, :p,
  args: 'number',
  desc: "Specify an alternate port number"
end

r.args       # Get all arguments received, including trailing args
r.arg[:host] # Get the value of the `host` argument
r.opt[:port] # Get the value of the `port` option
r.count[:v]  # Get the number of times an option was toggled
```

The `CLI.report` method yields a `Spec` instance, which we'll call `s`. Calls to
this instance will define how the command line is parsed. The online usage
information will also be generated from this spec.

`s` has four important methods:

### Name and description

The `name` method sets the name of the program to use in usage information. It
expects a string. This should probably be the same as the name of the
executable.

The `desc` method sets a description of the program for generating usage
information. It expects a string.

```ruby
s.name 'example'
s.desc "An example demonstrating usage of ark-cli"
```

### Declaring arguments

The `args` method defines what arguments the program will expect.

Declaring two named, expected arguments:

```ruby
s.args 'host', 'port'
```

Declare optional arguments as a hash with default values:

```ruby
s.args 'host', {'port' => 22, 'user' => ENV['USER']}
```

Declaring a variadic interface with a glob, `'dest...'`

```ruby
s.args 'target', 'dest...'
```

### Declaring options

The `opt` method defines options.

Flags are simple options without arguments:

```ruby
s.opt :verbose, :v,
  desc: "Increase verbosity"
```

Flags are false by default and set true when given on the command line. A count
is kept of the number of times the flag was specified, and stored in the report
as `r.count`. The `desc` field is used to generate usage information.

Options can also take arguments:

```ruby
s.opt :port, :p,
  args: 'number',
  desc: "Specify an alternate port number"
```



## Inspecting the `Report` object

The `Ark::CLI#report` method returns a `Report` instance which we can inspect
for information parsed from the command line.

Supposing `r` is a returned `Report` instance, we can get all arguments with the
`r.args` method. This will include any trailing arguments.

```ruby
host, path = r.args
```

Get the value of a named argument with the `r.arg` method:

```ruby
host = r.arg[:host]
path = r.arg[:path]
```

Inspect the value of an option with `r.opt`:

```ruby
verbose = r.opt[:v]
port = r.opt[:port]
```

Get a count of the number of times a flag was specified with `r.count`:

```ruby
verbosity = r.count[:verbose]
```

Get an array of trailing arguments with `r.trailing`:

```ruby
path1, path2 = r.trailing
```



## Usage information

A help option is defined for all interfaces with the `-h` and `--help` flags.
When the help option is given, the program will print usage information and exit
immediately.  Usage information is constructed from the `Spec` built during the
CLI declaration.

Usage information for the above declaration would look like this:

    example [OPTION...] HOST PATH

        An example demonstrating usage of ark-cli

    OPTIONS:

        -h --help
            Print usage information

        -v --verbose
            Increase verbosity

        -p --port NUMBER
            Specify an alternate port number



## Example script

A working example script with comments can be found at `example/hello.rb` --
invoke the script with the `--help` option for usage information.

