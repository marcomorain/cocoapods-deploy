module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Deploy < Command

      include Project

      self.summary = 'Install project dependencies to Podfile.lock versions without pulling down full podspec repo.'

      self.description = <<-DESC
        Install project dependencies to Podfile.lock versions without pulling down full podspec repo.
      DESC

      def initialize(argv)
        super
        apply_monkey_patch
      end

      def validate!
        super
      end

      def apply_monkey_patch
        Installer::Analyzer.class_eval do
          def sources
            []
          end
        end
      end

      def apply_monkey_patch
        Podfile.class_eval do

          alias_method :original_dependencies, :dependencies

          def dependencies
            UI.section('Deploying Pods') do
              original_dependencies.reject(&:external_source).map do |dep|
                version = config.lockfile.version(dep.name)
                url = "https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/#{dep.name}/#{version}/#{dep.name}.podspec.json"

                dep.external_source = { :podspec => url }
                dep.specific_version = nil
                dep.requirement = Requirement.create({ :podspec => url })

                UI.puts("- #{dep}")
              end
            end
          end
        end
      end

      def run
        verify_podfile_exists!
        verify_lockfile_exists!

        apply_monkey_patch

        puts config.podfile.dependencies

        config.skip_repo_update = true
        run_install_with_update(false)
      end
    end
  end
end
