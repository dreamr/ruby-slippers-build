require 'term/ansicolor'
require "./lib/build_env"

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
  RubySlippers::BuildEnv::Tasks.new.build!
end