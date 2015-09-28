# ark-cli - a command line interface library for Ruby
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


require 'ark/util'
include ARK::Log

require_relative 'cli/argument.rb'
require_relative 'cli/option.rb'
require_relative 'cli/interface.rb'
require_relative 'cli/spec.rb'
require_relative 'cli/report.rb'


module ARK # :nodoc:

# A library for handling options and arguments from the command line.
#
# Call #report to define a new interface and parse the command line. See
# +README.md+ or +example/hello.rb+ for more information.
module CLI
  # :call-seq:
  # report(input=ARGV) { |spec| ... } => Report
  #
  # Convenience method for interface declarations. Yields a +Spec+ instance and
  # returns a +Report+ instance for inspection.
  #
  # +args+ is an array of strings, which defaults to ARGV
  def self.report(args=ARGV, &block)
    i = Interface.new(args, &block)
    return i.report
  end
end

end # module ARK

