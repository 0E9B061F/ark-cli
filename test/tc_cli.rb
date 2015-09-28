require_relative '../lib/ark/cli.rb'
require 'test/unit'


class TestARKCLI < Test::Unit::TestCase

	def test_args
		# No args given
		r = ARK::CLI.report [] {|s| }
		assert_equal(0, r.args.length)

		# One arg given
		r = ARK::CLI.report ['a'] {|s| }
		assert_equal(1, r.args.length)
		assert_equal(1, r.trailing.length)

		# 3 args given
		r = ARK::CLI.report ['a', 'b', 'c'] {|s| }
		assert_equal(3, r.args.length)
		assert_equal(3, r.trailing.length)

		# 2 required arguemnts with trailing args
		r = ARK::CLI.report ['a', 'b', 'c', 'd', 'e'] {|s| s.args 'one', 'two'}
		assert_equal(5, r.args.length)
		assert_equal(3, r.trailing.length)
		assert_equal('a', r.arg('one'))
		assert_equal('b', r.arg('two'))
		assert_equal('c', r.trailing[0])
		assert_equal('d', r.trailing[1])
		assert_equal('e', r.trailing[2])

		# argument defaults
		r = ARK::CLI.report ['a', 'b'] {|s| s.args 'foo', 'bar:100', 'baz:200'}
		assert_equal(3, r.args.length)
		assert_equal(0, r.trailing.length)
		assert_equal('a', r.arg('foo'))
		assert_equal('b', r.arg('bar'))
		assert_equal('200', r.arg('baz'))

		# variadic args
		r = ARK::CLI.report ['a', 'b', 'c', 'd', 'e'] {|s| s.args 'foo', 'bar...'}
		assert_equal(5, r.args.length)
		assert_equal(0, r.trailing.length)
		assert_equal('a', r.arg('foo'))
		assert_equal('b', r.arg('bar')[0])
		assert_equal('c', r.arg('bar')[1])
		assert_equal('d', r.arg('bar')[2])
		assert_equal('e', r.arg('bar')[3])

		# defaults mixed with variadic args
		r = ARK::CLI.report ['a', 'b', 'c', 'd', 'e'] {|s| s.args 'foo', 'bar:42', 'baz...'}
		assert_equal(5, r.args.length)
		assert_equal(0, r.trailing.length)
		assert_equal('a', r.arg('foo'))
		assert_equal('b', r.arg('bar'))
		assert_equal('c', r.arg('baz')[0])
		assert_equal('d', r.arg('baz')[1])
		assert_equal('e', r.arg('baz')[2])
	end

	def test_errors
		# Single short option
		assert_raise(ARK::CLI::Spec::NoSuchOptionError) do
			ARK::CLI.report ['-v'] {|s| }
		end

		# Many short options in a compound
		assert_raise(ARK::CLI::Spec::NoSuchOptionError) do
			ARK::CLI.report ['-compound'] {|s| }
		end

    # Long name form
		assert_raise(ARK::CLI::Spec::NoSuchOptionError) do
			ARK::CLI.report ['--longform'] {|s| }
		end

    # Mixed forms
		assert_raise(ARK::CLI::Spec::NoSuchOptionError) do
			ARK::CLI.report ['-v', '--longform'] {|s| }
		end

    # Mixed with args
		assert_raise(ARK::CLI::Spec::NoSuchOptionError) do
			ARK::CLI.report ['-v', '--longform', 'foo', 'bar'] {|s| }
		end

    # Placing an option expecting an argument in the middle of a compound
		assert_raise(ARK::CLI::Interface::SyntaxError) do
			ARK::CLI.report ['-fv'] {|s| s.opt :verbose, :v; s.opt :file, :f, args: 'name'}
		end

    # Placing a variadic argument before the end of the argument list
		assert_raise(ARK::CLI::Spec::ArgumentSyntaxError) do
			ARK::CLI.report [] {|s| s.args 'foo', 'bar...', 'baz'}
		end
	end

	def test_flags
		# Single toggle of a single flag
		r = ARK::CLI.report ['-t'] do |s|
			s.opt :t, :test
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_equal 1, r.count(:test)

		# Multiple toggles of a single flag
		r = ARK::CLI.report ['-ttttt'] do |s|
			s.opt :t, :test
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_equal 5, r.count(:test)

		# Single toggle of a long-name flag
		r = ARK::CLI.report ['--test'] do |s|
			s.opt :t, :test
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_equal 1, r.count(:test)

		# Multiple toggles of a long-name flag
		r = ARK::CLI.report ['--test', '--test', '--test'] do |s|
			s.opt :t, :test
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_equal 3, r.count(:test)

		# Testing the default state of a flag (untoggled)
		r = ARK::CLI.report ['foo'] do |s|
			s.opt :t, :test
		end
		assert_false r.opt(:t)
		assert_false r.opt(:test)
		assert_equal 0, r.count(:test)

		# Toggling multiple flags once
		r = ARK::CLI.report ['-tx'] do |s|
			s.opt :t, :test
			s.opt :x, :example
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_true r.opt(:x)
		assert_true r.opt(:example)
		assert_equal 1, r.count(:test)
		assert_equal 1, r.count(:example)

		# Toggling multiple multiple times
		r = ARK::CLI.report ['-tttxxxxx'] do |s|
			s.opt :t, :test
			s.opt :x, :example
		end
		assert_true r.opt(:t)
		assert_true r.opt(:test)
		assert_true r.opt(:x)
		assert_true r.opt(:example)
		assert_equal 3, r.count(:test)
		assert_equal 5, r.count(:example)
	end

	def test_options
		# Specifying one option with one argument
		r = ARK::CLI.report ['-a', 'foo'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('foo', r.opt(:a))
		assert_equal([nil, nil], r.opt(:b))

		# Specifying one option with multiple arguments
		r = ARK::CLI.report ['-b', 'foo', 'bar'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_nil(r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:b))

		# Specifying multiple options
		r = ARK::CLI.report ['-a', 'test', '-b', 'foo', 'bar'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:b))

		# Specifying an option at the end of a compound
		r = ARK::CLI.report ['-fa', 'test'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_true(r.opt(:flag))

		# Trying to specify an option in the middle of a compound
		assert_raise(ARK::CLI::Interface::SyntaxError) do
			r = ARK::CLI.report ['-af', 'test'] do |s|
				s.opt :f, :flag
				s.opt :a, :opta, args: ['one']
				s.opt :b, :optb, args: ['one', 'two']
			end
		end

		# Specifying an option by its long name
		r = ARK::CLI.report ['--opta', 'test'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:opta))

		# Specifying an option with arguments
		r = ARK::CLI.report ['--opta', 'test', 'foo', 'bar'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:opta))
		assert_equal(['foo', 'bar'], r.args)

		# Specifying multiple options with long and short names
		r = ARK::CLI.report ['-a', 'test', '--optb', 'foo', 'bar'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:optb))

		# Specifying multiple options with long and short names and a flag
		r = ARK::CLI.report ['-fa', 'test', '--optb', 'foo', 'bar'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:optb))
		assert_true(r.opt(:flag))

		# Specifying multiple options with long and short names and a flag, with args
		r = ARK::CLI.report ['-fa', 'test', '--optb', 'foo', 'bar', 'arg1', 'arg2'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:optb))
		assert_true(r.opt(:flag))
		assert_equal(['arg1','arg2'], r.args)

		# Testing flag counting with a full commandline
		r = ARK::CLI.report ['-ff', '-fffa', 'test', '--optb', 'foo', 'bar', 'arg1', 'arg2'] do |s|
			s.opt :f, :flag
			s.opt :a, :opta, args: ['one']
			s.opt :b, :optb, args: ['one', 'two']
		end
		assert_equal('test', r.opt(:a))
		assert_equal(['foo', 'bar'], r.opt(:optb))
		assert_true(r.opt(:flag))
		assert_equal(5, r.count(:flag))
		assert_equal(['arg1','arg2'], r.args)
	end
end

