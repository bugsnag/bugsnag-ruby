module Bugsnag::Middleware
  ##
  # Attaches delayed_job information to an error report
  class DelayedJob
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      job = report.request_data[:delayed_job]
      if job
        job_data = {
          :class => job.class.name,
          :id => job.id
        }
        job_data[:priority] = job.priority if job.respond_to?(:priority)
        job_data[:run_at] = job.run_at if job.respond_to?(:run_at)
        job_data[:locked_at] = job.locked_at if job.respond_to?(:locked_at)
        job_data[:locked_by] = job.locked_by if job.respond_to?(:locked_by)
        job_data[:created_at] = job.created_at if job.respond_to?(:created_at)
        job_data[:queue] = job.queue if job.respond_to?(:queue)

        if job.respond_to?('payload_object') && job.payload_object.respond_to?('job_data')
          job_data[:active_job] = job.payload_object.job_data
        end

        if job.respond_to?(:attempts)
          max_attempts = (job.respond_to?(:max_attempts) && job.max_attempts) || Delayed::Worker.max_attempts
          job_data[:attempts] = "#{job.attempts + 1} / #{max_attempts}"
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
          job_data[:payload] = p
        end
        report.add_tab(:job, job_data)
      end
      @bugsnag.call(report)
    end
  end
end
