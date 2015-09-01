require_relative '../lib/cli.rb'
require 'test/unit'


class TestS25CLI < Test::Unit::TestCase

	def test_empty_cli
		# Empty interface with no arguments given
		cli = S25::CLI.begin [] {|cli| }
		assert_equal(0, cli.args.length)

		# Empty interface with one argument
		cli = S25::CLI.begin ['foo'] {|cli| }
		assert_equal(1, cli.args.length)

		# Empty interface with multiple args
		cmdline = ['foo', 'bar', 'baz']
		cli = S25::CLI.begin(cmdline) {|cli| }
		assert_equal(3, cli.args.length)
		assert_equal(cmdline, cli.args)
	end

	def test_bad_options
		# Single short option
		assert_raise(S25::CLI::NoSuchOptionError) do
			S25::CLI.begin ['-v'] {|cli| }
		end
		# Many short options in a compound
		assert_raise(S25::CLI::NoSuchOptionError) do
			S25::CLI.begin ['-verylongmanyoptions'] {|cli| }
		end

		assert_raise(S25::CLI::NoSuchOptionError) do
			S25::CLI.begin ['--longform'] {|cli| }
		end
		assert_raise(S25::CLI::NoSuchOptionError) do
			S25::CLI.begin ['-v', '--longform'] {|cli| }
		end
		assert_raise(S25::CLI::NoSuchOptionError) do
			S25::CLI.begin ['-v', '--longform', 'foo', 'bar'] {|cli| }
		end
	end

	def test_flags
		# Single toggle of a single flag
		cli = S25::CLI.begin ['-t'] do |cli|
			cli.opt :t, :test
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_equal 1, cli.count(:test)

		# Multiple toggles of a single flag
		cli = S25::CLI.begin ['-ttttt'] do |cli|
			cli.opt :t, :test
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_equal 5, cli.count(:test)

		# Single toggle of a long-name flag
		cli = S25::CLI.begin ['--test'] do |cli|
			cli.opt :t, :test
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_equal 1, cli.count(:test)

		# Multiple toggles of a long-name flag
		cli = S25::CLI.begin ['--test', '--test', '--test'] do |cli|
			cli.opt :t, :test
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_equal 3, cli.count(:test)

		# Testing the default state of a flag (untoggled)
		cli = S25::CLI.begin ['foo'] do |cli|
			cli.opt :t, :test
		end
		assert_false cli[:t]
		assert_false cli[:test]
		assert_equal 0, cli.count(:test)

		# Toggling multiple flags once
		cli = S25::CLI.begin ['-tx'] do |cli|
			cli.opt :t, :test
			cli.opt :x, :example
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_true cli[:x]
		assert_true cli[:example]
		assert_equal 1, cli.count(:test)
		assert_equal 1, cli.count(:example)

		# Toggling multiple multiple times
		cli = S25::CLI.begin ['-tttxxxxx'] do |cli|
			cli.opt :t, :test
			cli.opt :x, :example
		end
		assert_true cli[:t]
		assert_true cli[:test]
		assert_true cli[:x]
		assert_true cli[:example]
		assert_equal 3, cli.count(:test)
		assert_equal 5, cli.count(:example)
	end

	def test_options
		# Specifying one option with one argument
		cli = S25::CLI.begin ['-a', 'foo'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('foo', cli[:a])
		assert_nil(cli[:b])

		# Specifying one option with multiple arguments
		cli = S25::CLI.begin ['-b', 'foo', 'bar'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_nil(cli[:a])
		assert_equal(['foo', 'bar'], cli[:b])

		# Specifying multiple options
		cli = S25::CLI.begin ['-a', 'test', '-b', 'foo', 'bar'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_equal(['foo', 'bar'], cli[:b])

		# Specifying an option at the end of a compound
		cli = S25::CLI.begin ['-fa', 'test'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_true(cli[:flag])

		# Trying to specify an option in the middle of a compound
		assert_raise(S25::CLI::SyntaxError) do
			cli = S25::CLI.begin ['-af', 'test'] do |cli|
				cli.opt :f, :flag
				cli.opt :a, :opta, args: ['one']
				cli.opt :b, :optb, args: ['one', 'two']
			end
		end

		# Specifying an option by its long name
		cli = S25::CLI.begin ['--opta', 'test'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:opta])

		# Specifying an option with arguments
		cli = S25::CLI.begin ['--opta', 'test', 'foo', 'bar'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:opta])
		assert_equal(['foo', 'bar'], cli.args)

		# Specifying multiple options with long and short names
		cli = S25::CLI.begin ['-a', 'test', '--optb', 'foo', 'bar'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_equal(['foo', 'bar'], cli[:optb])

		# Specifying multiple options with long and short names and a flag
		cli = S25::CLI.begin ['-fa', 'test', '--optb', 'foo', 'bar'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_equal(['foo', 'bar'], cli[:optb])
		assert_true(cli[:flag])

		# Specifying multiple options with long and short names and a flag, with args
		cli = S25::CLI.begin ['-fa', 'test', '--optb', 'foo', 'bar', 'arg1', 'arg2'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_equal(['foo', 'bar'], cli[:optb])
		assert_true(cli[:flag])
		assert_equal(['arg1','arg2'], cli.args)

		# Testing flag counting with a full commandline
		cli = S25::CLI.begin ['-ff', '-fffa', 'test', '--optb', 'foo', 'bar', 'arg1', 'arg2'] do |cli|
			cli.opt :f, :flag
			cli.opt :a, :opta, args: ['one']
			cli.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', cli[:a])
		assert_equal(['foo', 'bar'], cli[:optb])
		assert_true(cli[:flag])
		assert_equal(5, cli.count(:flag))
		assert_equal(['arg1','arg2'], cli.args)
	end
end

