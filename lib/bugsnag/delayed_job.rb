require 'delayed_job'

# See Issue #99
unless defined?(Delayed::Plugins::Plugin)
  raise LoadError, "bugsnag requires delayed_job > 3.x"
end

unless defined? Delayed::Plugins::Bugsnag
  module Delayed
    module Plugins


      class Bugsnag < Plugin
        module Notify
          def error(job, error)
            ::Bugsnag.auto_notify(error)
            super if defined?(super)
          end
        end

        callbacks do |lifecycle|
          lifecycle.before(:invoke_job) do |job|
            payload = job.payload_object
            payload = payload.object if payload.is_a? Delayed::PerformableMethod
            payload.extend Notify
          end
        end
      end
    end
  end

  Delayed::Worker.plugins << Delayed::Plugins::Bugsnag
end
