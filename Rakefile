require 'rubygems/package_task'

v = `git describe --tags`.strip.tr('-', '.')
c = 2 - v.count('.')
p = c >= 0 ? '.0' * c : ''
Version = v+p

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name     = 'ark-cli'
  s.version  = Version
	s.license  = 'GPL-3.0'
  s.summary  = "Simple commandline interface"
	s.authors  = ["Macquarie Sharpless"]
	s.email    = ["macquarie.sharpless@gmail.com"]
	s.homepage = "https://github.com/grimheart/ark-cli"
  s.description = <<EOF
A simple library for parsing options and arguments from the commandline. Parses
ARGV and returns an object holding information about what options were set on
the commandline, and what arguments were given.
EOF

  s.require_paths = ['lib']
  s.files = ['lib/cli.rb']
	s.add_dependency 'ark-util', '>= 0.1.0'
end

desc "Print the version for the current revision"
task :version do
	puts Version
end

desc "Open an IRB session with the library already require'd"
task :console do
  require 'irb'
  require 'irb/completion'
  require_relative 'lib/cli.rb'
  ARGV.clear
  IRB.start
end

desc "Run all test cases"
task :test do
	Dir['test/*'].select {|p| File.basename(p)[/^tc_.+\.rb$/] }.each do |path|
		system "ruby #{path}"
	end
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

