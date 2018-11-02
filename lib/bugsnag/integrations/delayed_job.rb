require 'delayed_job'

# See Issue #99
unless defined?(Delayed::Plugin)
  raise LoadError, "bugsnag requires delayed_job > 3.x"
end

module Delayed
  module Plugins
    class Bugsnag <  ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          begin
            Bugsnag.configuration.app_type = 'delayed_job'
            Bugsnag.configuration.set_request_data(:delayed_job, job)
            block.call(job, *args)
          rescue Exception => exception
            ::Bugsnag.notify(exception, true) do |report|
              report.severity = "error"
              report.severity_reason = {
                :type => ::Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
                :attributes => {
                  :framework => "DelayedJob"
                }
              }
            end
            raise
          ensure
            ::Bugsnag.configuration.clear_request_data
          end
        end
      end
    end
  end
end

Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::DelayedJob)
Delayed::Worker.plugins << Delayed::Plugins::Bugsnag
