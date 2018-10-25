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
            block.call(job, *args)
          rescue Exception => exception
            overrides = {
              :job => {
                :class => job.class.name,
                :id => job.id,
              },
            }
            overrides[:job][:priority] = job.priority if job.respond_to?(:priority)
            overrides[:job][:run_at] = job.run_at if job.respond_to?(:run_at)
            overrides[:job][:locked_at] = job.locked_at if job.respond_to?(:locked_at)
            overrides[:job][:locked_by] = job.locked_by if job.respond_to?(:locked_by)
            overrides[:job][:created_at] = job.created_at if job.respond_to?(:created_at)
            overrides[:job][:queue] = job.queue if job.respond_to?(:queue)

            if job.respond_to?('payload_object') && job.payload_object.respond_to?('job_data')
              overrides[:job][:active_job] = job.payload_object.job_data
            end

            if job.respond_to?(:attempts)
              max_attempts = (job.respond_to?(:max_attempts) && job.max_attempts) || Delayed::Worker.max_attempts
              overrides[:job][:attempts] = "#{job.attempts + 1} / #{max_attempts}"
              # +1 as "attempts" is zero-based and does not include the current failed attempt
            end

            if payload = job.payload_object
              p = {
                :class => payload.class.name,
              }
              p[:id]           = payload.id           if payload.respond_to?(:id)
              p[:display_name] = payload.display_name if payload.respond_to?(:display_name)
              p[:method_name]  = payload.method_name  if payload.respond_to?(:method_name)

              if payload.respond_to?(:args)
                p[:args] = payload.args
              elsif payload.respond_to?(:to_h)
                p[:args] = payload.to_h
              end

              if payload.is_a?(::Delayed::PerformableMethod) && (object = payload.object)
                p[:object] = {
                  :class => object.class.name,
                }
                p[:object][:id] = object.id if object.respond_to?(:id)
              end
              if payload.respond_to?(:job_data) && payload.job_data.respond_to?(:[])
                [:job_class, :arguments, :queue_name, :job_id].each do |key|
                  if (value = payload.job_data[key.to_s])
                    p[key] = value
                  end
                end
              end
              overrides[:job][:payload] = p
            end

            ::Bugsnag.notify(exception, true) do |report|
              report.severity = "error"
              report.severity_reason = {
                :type => ::Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
                :attributes => {
                  :framework => "DelayedJob"
                }
              }
              report.meta_data.merge! overrides
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

Delayed::Worker.plugins << Delayed::Plugins::Bugsnag
