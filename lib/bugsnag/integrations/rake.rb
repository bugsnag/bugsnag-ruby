require 'bugsnag'

Rake::TaskManager.record_task_metadata = true

class Rake::Task

  def execute_with_bugsnag(args=nil)
    Bugsnag.configuration.app_type = "rake"
    old_task = Bugsnag.configuration.request_data[:bugsnag_running_task]
    Bugsnag.configuration.set_request_data :bugsnag_running_task, self

    execute_without_bugsnag(args)

  rescue Exception => ex
    Bugsnag.notify(ex, true) do |report|
      report.severity = "error"
      report.set_handled_state({
        :type => "middleware_handler",
        :attributes => {
          :name => "rake"
        }
      })
    end
    raise
  ensure
    Bugsnag.configuration.set_request_data :bugsnag_running_task, old_task
  end

  alias_method :execute_without_bugsnag, :execute
  alias_method :execute, :execute_with_bugsnag
end

Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Rake)
