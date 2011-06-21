require 'term/ansicolor'
require "./lib/rake_helper"

# rake release
# => checks for a rerelease and msgs user (must increment build to release)
# => tags the tree with version
# => pushes gem to rubygems.org
# => pushes tags to github

desc "Tags and pushes to rubygems and gitub (no push or tag on fail)"
task :release do
  include SlipperEnv
  ENGINE_ROOT = File.expand_path("../../../engine",__FILE__)

  bad_return("Must be a new release, gem not released!") unless is_new_release?
  bad_return("Try a few more bigfixes or a patch, gem not released!") if too_many_releases?

  release_output = `cd #{ENGINE_ROOT} && rake gem:release`
  puts release_output

end