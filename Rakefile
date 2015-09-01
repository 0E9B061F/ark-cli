require 'rubygems/package_task'

task :console do
  require 'irb'
  require 'irb/completion'
  require_relative 'lib/cli.rb'
  ARGV.clear
  IRB.start
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Simple commandline interface for handling options"
  s.name = 's25-cli'
	s.authors = "Macquarie Sharpless"
  s.version = 0.1
  s.requirements << 's25-utility'
  s.require_path = 'lib'
  s.files = []
  s.description = <<EOF
A simple commandline interface for handling options. Parses ARGV and returns an
object holding information about what options were set on the commandline, and
what arguments were given.
EOF
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

