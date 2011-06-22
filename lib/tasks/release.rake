require 'term/ansicolor'
require "./lib/build_env"

# rake release
# => checks for a rerelease and msgs user (must increment build to release)
# => tags the tree with version
# => pushes gem to rubygems.org
# => pushes tags to github

desc "Tags and pushes to rubygems and gitub (no push or tag on fail)"
task :release do
  tasks = RubySlippers::BuildEnv::Tasks.new
  tasks.release!
end