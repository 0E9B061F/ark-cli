# ark-cli

[![Gem Version](https://badge.fury.io/rb/ark-cli.svg)](http://badge.fury.io/rb/ark-cli)

__ark-cli__ is a simple library for handling command line options and
arguments. See below for basic usage. Full documentation can be found at
http://www.rubydoc.info/github/grimheart/ark-cli



## Declaring an interface

We declare an interface like so:

    require 'ark/cli'

    cli = Ark::CLI.begin do |c|
      c.header name: 'example',
        args: [:host, :path],
        desc: "An example demonstrating usage of ark-cli"
      c.opt :v, :verbose,
        desc: "Increase verbosity"
      c.opt :p, :port,
        args: [:number],
        desc: "Specify an alternate port number"
    end

The `header` method defines the name of the program, a short description, and
an array of named arguments for the interface. The header method and all of its
arguments are optional.

The `opt` method defines options. Flags are options without arguments:

    c.opt :v, :verbose,
      desc: "Increase verbosity"

The `desc` field is used to provide usage information when the `--help` option
is given.

Options can take arguments as well:

    c.opt :p, :port,
      args: [:number],
      desc: "Specify an alternate port number"



## Inspecting the interface object

The Ark::CLI#begin method returns a CLI instance which we can inspect for
information from the command line.

Inspecting the value of an option:

    verbose = cli[:v]
    port = cli[:port]

We can also check how many times a flag was specified:

    verbosity = cli.count(:verbose)

We can get all arguments with the `args` method:

    host, path = cli.args

Or we can get a named argument with the `arg` method:

    host = cli.arg(:host)

A working example script with comments can be found at `example/hello.rb` --
invoke the script with the `--help` option for usage information.



## Usage information

Ark::CLI defines one default option for all interfaces, the `-h` / `--help`
flag. When this flag is given, CLI will print usage information and immediately
exit the program. Usage information is constructed from the CLI declaration.

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

