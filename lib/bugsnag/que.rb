if defined?(::Que)
  Que.error_handler = proc do |error, job|
    begin
      job = job.dup # Make sure the original job object is not mutated.

      Bugsnag.configuration.app_type = "que"

      Bugsnag.auto_notify(error) do |notification|
        job[:error_count] += 1

        # If the job was scheduled using ActiveJob then unwrap the job details for clarity:
        if job[:job_class] == "ActiveJob::QueueAdapters::QueAdapter::JobWrapper"
          wrapped_job = job[:args].last
          wrapped_job = wrapped_job.each_with_object({}) { |(k, v), result| result[k.to_sym] = v } # Symbolize keys

          # Align key names with keys in `job`
          wrapped_job[:queue] = wrapped_job.delete(:queue_name)
          wrapped_job[:args]  = wrapped_job.delete(:arguments)

          job.merge!(wrapper_job_class: job[:job_class], wrapper_job_id: job[:job_id]).merge!(wrapped_job)
        end

        notification.add_tab(:job, job)
      end
    rescue => e
      # Que supresses errors raised by its error handler to avoid killing the worker. Log them somewhere:
      Bugsnag.warn("Failed to notify Bugsnag of error in Que job (#{e.class}): #{e.message} \n#{e.backtrace[0..9].join("\n")}")
      raise
    end
  end
end
