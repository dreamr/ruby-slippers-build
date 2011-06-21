require 'term/ansicolor'
require "./lib/rake_helper"

# rake build (bug|patch|release)
# an unsuccessful build msgs user and exits
# a successful build looks like this:
#
# => cds to ./engine and runs unit and integration tests
# => cds to ./base and runs client rake tests               ** TODO
# => increments the build based on build type
# => builds new gemspec
# => builds new gem in ./engine/pkg
# => writes to buildfile with version so we know we cant release

namespace :build do
  include SlipperEnv
  version_types = %w(bugfix patch release)
  version_egs = ["0.0.X", "0.X.0", "X.0.0"]
  version_types.each_with_index do |type, i|
    desc "Increments version (#{version_egs[i]}), rebuilds the gemspec, then rebuilds the gem (no increment on fail)"
    task "#{type}".to_sym do
      bad_return("Gem not built!") unless engine_unit_tests_pass?
      bad_return("Gem not built!") unless engine_integration_tests_pass?
      bad_return("Gem not built!") unless gem_builds?
      increment_version(type, File.open(ENGINE_ROOT+"/VERSION").read)
    end
  end
end