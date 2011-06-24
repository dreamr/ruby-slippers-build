require 'rubygems'
require 'rake'
require './lib/build_env'
include RubySlippers::BuildEnv

Dir.glob('lib/tasks/*.rake').each { |file| import file }

task :environment do
  # todo
end

def silence(&block)
  old_out = $stdout
  $stdout = File.new('/dev/null', 'w')
  retval = block.call
  $stdout = old_out
  retval.to_s
end

task :push => :environment do
  push_base
  push_engine
end

task :build => 'build:bugfix'
task :default => :build