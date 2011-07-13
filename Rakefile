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

namespace :test do
  %w(unit integration).each do |type|
    desc "Run #{type} tests"
    task type.to_sym => :environment do
      tasks = RubySlippers::BuildEnv::Tasks.new
      tasks.send "run_#{type}_tests".to_sym
    end
  end
end

task :build => 'build:bugfix'
task :default => :build