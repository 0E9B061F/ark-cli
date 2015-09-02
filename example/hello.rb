#!/usr/bin/env ruby

# This is an example script to show usage of the Ark::CLI library
# Invoke the script with the '-h' option to see usage information

require 'ark/cli'


# Define and parse the commandline interface by calling Ark::CLI#begin
cli = Ark::CLI.begin do |c|

  # Define the name of the program, its arguments and a description
  c.header name: 'hello.rb',
    args: [:name],
    desc: "ark-cli example script. Provide a NAME to recieve a greeting."

  # Define a flag with two names, which will be given as -v and --verbose on
  # the command line
  c.opt :v, :verbose,
    desc: "Increase verbosity"

  # Define an option which expects an argument
  c.opt :f, :friend,
    args: [:name],
    desc: "Inquire about a friend"

end


# Get the number of times -v was toggled
verbosity = cli.count(:verbose)

# Get the value of the 'name' argument
name = cli.arg(:name).capitalize

# Get the value given for the --friend option
friend = cli[:friend]


# Craft an appropriate greeting
if verbosity == 0
  greeting = "Hello, #{name}!"
  inquiry = "How's #{friend}?"
elsif verbosity == 1
  greeting = "Greetings and salutations, #{name} - and what a fine day!"
  inquiry = "Say, how's #{friend} doing?"
elsif verbosity > 1
  greeting = "Greetings and salutations, #{name}, my friend, blood beating in my heart - you've been well, I trust? Of course you have, look at you! The splitting image of health. No, don't say a word - modesty is your only fault, if I might say so."
  inquiry = "And how is #{friend}? Quite well, I hope, I truly do - truly a fine person of outstanding character, that #{friend}! And no doubt - make no mistake! - a perfectly suitable friend for one such as yourself."
end

if friend
  puts "#{greeting} #{inquiry}"
else
  puts greeting
end

