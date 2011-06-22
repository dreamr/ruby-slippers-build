require 'rake'
require 'logger'
require 'date'
require 'term/ansicolor'
require './engine/lib/ext/ext'

module RubySlippers
  module BuildEnv
    
    ENGINE_ROOT     = File.expand_path("../../engine", __FILE__)
    BASE_ROOT       = File.expand_path("../../base", __FILE__)
    STD_TEST_ERROR  = "Rerun your test suite before you continue"

    BUGFIX = 2
    PATCH = 1
    RELEASE = 0
    
    class Tasks
      include Term::ANSIColor
      include Rake::DSL
      
      def build!
        version_types = %w(bugfix patch release)
        version_egs = ["0.0.X", "0.X.0", "X.0.0"]
        version_types.each_with_index do |type, i|
          desc "Increments version (#{version_egs[i]}), rebuilds the gemspec, then rebuilds the gem (no increment on fail)"
          task "#{type}".to_sym do
            bad_return("Gem not built!") unless engine_unit_tests_pass?
            bad_return("Gem not built!") unless engine_integration_tests_pass?
            bad_return("Gem not built!") unless base_integration_tests_pass?
            bad_return("Gem not built!") unless gem_builds?
            increment_version(type, File.open(ENGINE_ROOT+"/VERSION").read)
          end
        end
      end
    
      def release!
        bad_return("Must be a new release, gem not released!") unless is_new_release?
        bad_return("Try a few more bigfixes or a patch, gem not released!") if too_many_releases?
        bad_return("The gem could not be published!") unless gem_publishes?
        
        print yellow, bold, "Gem v#{new_version} pushed to rubygems.org!", reset, "\n"
        
        log_release("Last released v#{build_version.join(".")} #{timestamp}")
      end
    
    private
    
      %w(build release).each do |type|
        define_method "log_#{type}" do |msg|
          File.open(ENGINE_ROOT+"/log/#{type}.log", "w") {|file| file.write msg}
        end
      end

      def bad_return(msg)
        print red, bold, msg, reset, "\n"
        exit
      end

      def release_version
        path=ENGINE_ROOT+"/log/release.log"
        File.open(path).read.scan(/([0-9]+)\.([0-9]+)\.([0-9]+)/).flatten
      end

      def build_version
        path=ENGINE_ROOT+"/log/build.log"
        File.open(path).read.scan(/([0-9]+)\.([0-9]+)\.([0-9]+)/).flatten
      end

      %w(unit integration).each do |type|
        define_method "engine_#{type}_tests_pass?" do
          print yellow, bold, "Running engine #{type} tests...", reset, "\n"
          test_output = `cd #{ENGINE_ROOT} && rake test:#{type}`
          unless pass?(test_output)
            print red, bold, "Engine #{type} test failed! #{STD_TEST_ERROR}", reset, "\n"
            return false
          end
          print green, bold, "All engine #{type} tests passed!", reset, "\n"
          true
        end
      end
      
      def base_integration_tests_pass?
        print yellow, bold, "Running base integration tests...", reset, "\n"
        test_output = `cd #{BASE_ROOT} && rake test:integration`
        unless pass?(test_output)
          print red, bold, "Base #{type} test failed! #{STD_TEST_ERROR}", reset, "\n"
          return false
        end
        print green, bold, "All base integration tests passed!", reset, "\n"
        true
      end
      
      def gem_publishes?
        release_output = `cd #{ENGINE_ROOT} && git add . && git commit -m 'releasing new gem' && rake gem:release`
        return true if release_output =~ /Successfully registered gem/
        false
      end

      def gem_builds?
        gemspec_output = `cd #{ENGINE_ROOT} && rake gem:gemspec`
        unless builds?(gemspec_output)
          print red, bold, "The gem could not be built!", reset, "\n"
          return false
        end
        build_output = `cd #{ENGINE_ROOT} && rake gem:build`
        unless builds?(build_output)
          print red, bold, "The gem could not be built!", reset, "\n"
          return false
        end
        print green, bold, "The gem was built and placed in engine/pkg.", reset, "\n"
        true
      end

      def increment_version(type, current_version)
        versions = current_version.split(".")
        case type
        when "bugfix"
          versions[BUGFIX]=versions[BUGFIX].to_i+1
        when "patch"
          versions[BUGFIX]=0
          versions[PATCH]=versions[PATCH].to_i+1
          versions[RELEASE]=0
        when "release"
          versions[RELEASE]=versions[RELEASE].to_i+1
          versions[PATCH]=0
          versions[BUGFIX]=0
        end
        new_version = versions.join(".")
        File.open(ENGINE_ROOT+"/VERSION", "w") do |file|
          file.write new_version
          print yellow, bold, "Now at v#{new_version}!", reset, "\n"
        end
        log_build("Last built v#{new_version} #{timestamp}")
      end

      def pass?(output)
        output.scan(/([0-9]+) passes, ([0-9]+) failures, ([0-9]+) errors/) do |pass, fail, error|
          return false if fail == 0 && error == 0
          true
        end
      end

      def builds?(output)
        return true if output =~ /gemspec is valid/
        return true if output =~ /Successfully built RubyGem/
        false    
      end

      def is_new_release?
        build_version[BUGFIX] != release_version[BUGFIX]
      end

      def too_many_releases?
        return false if build_version[RELEASE] != release_version[RELEASE]
        return false if build_version[PATCH] != release_version[PATCH]
        build_version[BUGFIX].to_i < release_version[BUGFIX].to_i+3
      end
      
      def timestamp
        lambda {|now| now.strftime("on %m/%d/%Y at %H:%m") }.call(DateTime.now)
      end
    end
  end  
end
