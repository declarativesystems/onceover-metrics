# Create a class to hold the new command definition.  The class defined should
# match the file we are contained in.
require 'onceover/metrics/metrics'
class Onceover
  module Metrics
    class CLI

        # Static method defining the new command to be added
        def self.command
          @cmd ||= Cri::Command.define do
            name 'metrics'
            usage 'metrics [--format NAME]'
            summary "Metrics plugin for Onceover"
            description <<-DESCRIPTION
Output some handy code metrics so you can guage the size of your Puppet code
            DESCRIPTION

            option nil, :format, 'Format - json or text', :argument => :optional, default: "text"
            flag nil, :detailed, 'Output per-class stats in text mode', :argument => :optional, default: false

            run do |opts, args, cmd|
              Onceover::Metrics::Metrics.run opts
            end
          end
        end
      end
  end
end

# Register the new command with onceover.  The method you add must match your 
# own code
Onceover::CLI::Run.command.add_command(Onceover::Metrics::CLI.command)

