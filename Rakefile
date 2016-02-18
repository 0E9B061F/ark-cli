require 'rubygems/package_task'
require 'rdoc/task'

require 'ark/util'


Version     = ARK::Git.version
VersionLine = ARK::Git.version_line

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name     = 'ark-cli'
  s.version  = Version
  s.license  = 'GPL-3.0'
  s.summary  = "Command line interface library"
  s.authors  = ["Macquarie Sharpless"]
  s.email    = ["macquarie.sharpless@gmail.com"]
  s.homepage = "https://github.com/grimheart/ark-cli"
  s.description = <<EOF
A library for parsing options and arguments from the commandline. Parses ARGV
and returns an object holding information about what options were set on the
commandline, and what arguments were given.
EOF

  s.require_paths = ['lib']
  s.files = ['README.md', 'lib/ark/cli.rb'] + Dir['lib/ark/cli/*']
  s.add_dependency 'ark-util', '~> 0.5', '>= 0.5.0'
end

desc "Print the version for the current revision"
task :version do
  puts VersionLine
end

desc "Open an IRB session with the library already require'd"
task :console do
  require 'irb'
  require 'irb/completion'
  require_relative 'lib/ark/cli.rb'
  ARGV.clear
  IRB.start
end

desc "Run all test cases"
task :test do
  Dir['test/*'].select {|p| File.basename(p)[/^tc_.+\.rb$/] }.each do |path|
    system "ruby #{path}"
  end
end

desc "Build a gem then install"
task :install => [:clobber, :gem] do
  system "gem install pkg/#{spec.name}-#{Version}.gem"
end

desc "Push a gem to rubygems.org"
task :push => :gem do
  system "gem push pkg/#{spec.name}-#{Version}.gem"
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new do |rd|
  rd.main       = 'README.md'
  rd.rdoc_dir   = 'doc'
  rd.title      = "#{VersionLine} Documentation"
  rd.rdoc_files.include("README.md", "lib/ark/cli.rb", *Dir['lib/ark/cli/*'])
end

