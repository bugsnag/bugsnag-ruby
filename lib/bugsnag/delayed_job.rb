require 'delayed_job'

# See Issue #99
unless defined?(Delayed::Plugin)
  raise LoadError, "bugsnag requires delayed_job > 3.x"
end

unless defined? Delayed::Plugins::Bugsnag
  module Delayed
    module Plugins


      class Bugsnag < Plugin
        module Notify
          def error(job, error)
            overrides = {
              :job => {
                :class => job.class.name,
                :id => job.id,
              },
              :severity_reason => {
                :type => ::Bugsnag::Notification::UNHANDLED_EXCEPTION_MIDDLEWARE,
                :attributes => {
                  :framework => "DelayedJob"
                }
              }
            }
            if job.respond_to?(:queue) && (queue = job.queue)
              overrides[:job][:queue] = queue
            end
            if job.respond_to?(:attempts)
              overrides[:job][:attempts] = "#{job.attempts + 1} / #{Delayed::Worker.max_attempts}"
              # +1 as "attempts" is really previous attempts AFAICT, certainly it starts at 0.
            end
            if payload = job.payload_object
              p = {
                :class => payload.class.name,
              }
              p[:id]           = payload.id           if payload.respond_to?(:id)
              p[:display_name] = payload.display_name if payload.respond_to?(:display_name)
              p[:method_name]  = payload.method_name  if payload.respond_to?(:method_name)
              p[:args]         = payload.args         if payload.respond_to?(:args)
              if payload.is_a?(::Delayed::PerformableMethod) && (object = payload.object)
                p[:object] = {
                  :class => object.class.name,
                }
                p[:object][:id] = object.id if object.respond_to?(:id)
              end
              add_active_job_details(p, payload)
              overrides[:job][:payload] = p
            end

            ::Bugsnag.auto_notify(error, overrides)

            super if defined?(super)
          end

          def add_active_job_details(p, payload)
            if payload.respond_to?(:job_data) && payload.job_data.respond_to?(:[])
              [:job_class, :arguments, :queue_name, :job_id].each do |key|
                if (value = payload.job_data[key.to_s])
                  p[key] = value
                end
              end
            end
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
