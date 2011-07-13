require 'rake'
require 'rake'
require 'logger'
require 'date'
require './engine/lib/ext/ext'
require './lib/ext/silencer'
require './lib/ext/console_color'

module RubySlippers
  module BuildEnv
    include ConsoleColor
    include Silencer
    
    REPOSITORY      = 
    ROOT            = File.expand_path("../../", __FILE__)
    ENGINE_ROOT     = File.expand_path("../../engine", __FILE__)
    BASE_ROOT       = File.expand_path("../../base", __FILE__)
    DEPLOY_ROOT     = File.expand_path("../../deploy", __FILE__)
    WIKI_ROOT       = File.expand_path("../../wiki", __FILE__)

    BUGFIX = 2
    PATCH = 1
    RELEASE = 0
    
    class Tasks
      include Rake::DSL
      
      %w(wiki engine base).each do |codebase|
        define_method "push_#{codebase}" do
          notify "pushing #{codebase} source..."
          retval = `cd #{RubySlippers::BuildEnv::ROOT}/#{codebase};git push`
          if retval =~ /Resolving deltas: 100%/
            gratify "#{codebase} source pushed to remote"
          else
            alert "could not push #{codebase} source"
          end
        end
      end
      
      def build!
        version_types = %w(bugfix patch release)
        version_egs = ["0.0.X", "0.X.0", "X.0.0"]
        version_types.each_with_index do |type, i|
          desc "Increments version (#{version_egs[i]}), rebuilds the gemspec, then rebuilds the gem (no increment on fail)"
          task "#{type}".to_sym do
            
            unless engine_unit_tests_pass?
              bad_return("Engine: Unit tests failed!")
            end
            
            unless engine_integration_tests_pass?
              bad_return("Engine: Integration tests failed!")
            end
            
            unless gem_builds?
              bad_return("Gem not built!")
            end
            
            copy_integration_tests
            
            unless app_was_deployed?
              bad_return("Could not deploy the app!")
            end
            
            unless deployed_integration_tests_pass?
              bad_return("Deployed Integration tests failed!")
            end
            
            increment_version(type, File.open(ENGINE_ROOT+"/VERSION").read)
            
            unless slaps_version_on_base_gemfile?
              bad_return("Could not edit base Gemfile for versioning!")
            end
          end
        end
      end
    
      def release!
        bad_return("Must be a new release, gem not released!") unless is_new_release?
        # bad_return("Try a few more bigfixes or a patch, gem not released!") if too_many_releases?
        bad_return("The gem could not be published!") unless gem_publishes?
        
        print yellow, bold, "Gem v#{build_version.join(".")} pushed to rubygems.org!", reset, "\n"
        
        log_release("Last released v#{build_version.join(".")} #{timestamp}")
      end
      
      %w(unit integration).each do |type|
        define_method "run_#{type}_tests" do
          output = `cd #{ENGINE_ROOT} && rake`
          puts output
          unless pass?(output)
            bad_return("Engine: #{type} tests failed!")
          end
        end
      end
    
    private
    
      def copy_integration_tests
        print yellow, bold, "Updating integration tests", reset, "\n"
        `cp #{ENGINE_ROOT}/test/integration/* #{BASE_ROOT}/test/integration`
        `cd #{BASE_ROOT} && git add .`
        `cd #{BASE_ROOT} && git commit -m 'updated integration tests'`
        `cd #{BASE_ROOT} && git push`
      end
    
      %w(build release).each do |type|
        define_method "log_#{type}" do |msg|
          File.open(ENGINE_ROOT+"/log/#{type}.log", "w") {|file| file.write msg}
        end
      end

      def bad_return(msg)
        print red, bold, msg, reset, "\n"
        exit -1
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
            print red, bold, "Engine #{type} test failed!", reset, "\n"
            return false
          end
          print green, bold, "All engine #{type} tests passed!", reset, "\n"
          true
        end
      end
      
      def deployed_integration_tests_pass?
        print yellow, bold, "Running deployed integration tests...", reset, "\n"
        test_output = `cd #{DEPLOY_ROOT}/slippers_test && rake test:integration`
        unless pass?(test_output)
          print red, bold, "Base #{type} test failed!", reset, "\n"
          return false
        end
        print green, bold, "All base integration tests passed!", reset, "\n"
        true
      end
      
      def gem_publishes?
        release_output = `cd #{ENGINE_ROOT} && git add . && git commit -m 'releasing new gem' && rake gem:release`
        if release_output =~ /Successfully registered gem/
          `cd #{BASE_ROOT} && git tag v#{build_version.join('.')} && git push --tags`
          return true 
        end
        false
      end
      
      def slaps_version_on_base_gemfile?
        gsub_file "#{BASE_ROOT}/Gemfile", /gem 'ruby_slippers', '[0-9]+\.[0-9]+\.[0-9]+'/, "gem 'ruby_slippers', '#{build_version.join('.')}'"
        text = File.read("#{BASE_ROOT}/Gemfile")
        text =~ /gem 'ruby_slippers', '#{build_version.join('.')}'/
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
      
      def gsub_file(path, regexp, *args, &block)
        content = File.read(path).gsub(regexp, *args, &block)
        File.open(path, 'wb') { |file| file.write(content) }
      end
      
      def app_was_deployed?
        path="#{ENGINE_ROOT}/pkg"
        print yellow, bold, 'Installing newly built gem', reset, "\n"
        `cd #{DEPLOY_ROOT} && gem install #{path}/ruby_slippers-#{build_version.join('.')}.gem`
        print yellow, bold, "Deploying app", reset, "\n"
        begin
          `rm -rf #{DEPLOY_ROOT}/slippers_test`
          `git clone #{REPOSITORY}.git #{DEPLOY_ROOT}/slippers_test`
          text = File.read("#{DEPLOY_ROOT}/slippers_test/Gemfile")
          text.gsub!(/gem 'ruby_slippers', '[0-9+]\.[0-9+]\.[0-9+]'/, "gem 'ruby_slippers', '#{build_version.join('.')}'")
          File.open("#{DEPLOY_ROOT}/slippers_test/Gemfile", "w") do |f|
            f.write text
          end
        rescue
          print red, bold, "Deployment failed!", reset, "\n"
        end
        print green, bold, "App deployed!", reset, "\n"
        true
      end
    end
  end  
end
