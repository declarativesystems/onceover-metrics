# Create a class to hold the new command definition.  The class defined should
# match the file we are contained in.
class Onceover
  module Metrics
    class CLI

        # Static method defining the new command to be added
        def self.command
          @cmd ||= Cri::Command.define do
            name 'metrics'
            usage 'metrics [--name NAME]'
            summary "Metrics plugin for Onceover"
            description <<-DESCRIPTION
This is a sample plugin to show you how to get started writing your own
plugins for onceover, The gateway drug to automated infrastructure testing 
with Puppet
            DESCRIPTION
          
            option :n,  :name, 'Who to say hello to', :argument => :optional

            run do |opts, args, cmd|
              # print a simple message - this is the point where you would
              # normally call out to a library to do the real work
              logger.info "Metrics, #{opts[:name]||'World'}!"
            end
          end
        end
      end
  end
end

# Register the new command with onceover.  The method you add must match your 
# own code
Onceover::CLI::Run.command.add_command(Onceover::Metrics::CLI.command)

