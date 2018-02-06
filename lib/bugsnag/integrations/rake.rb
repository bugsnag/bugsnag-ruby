require 'bugsnag'

Rake::TaskManager.record_task_metadata = true

class Rake::Task

  FRAMEWORK_ATTRIBUTES = {
    :framework => "Rake"
  }

  ##
  # Executes the rake task with Bugsnag setup with contextual data.
  def execute_with_bugsnag(args=nil)
    Bugsnag.configuration.app_type ||= "rake"
    old_task = Bugsnag.configuration.request_data[:bugsnag_running_task]
    Bugsnag.configuration.set_request_data :bugsnag_running_task, self

    execute_without_bugsnag(args)

  rescue Exception => ex
    Bugsnag.notify(ex, true) do |report|
      report.severity = "error"
      report.severity_reason = {
        :type => Bugsnag::Report::UNHANDLED_EXCEPTION_MIDDLEWARE,
        :attributes => FRAMEWORK_ATTRIBUTES
      }
    end
    raise
  ensure
    Bugsnag.configuration.set_request_data :bugsnag_running_task, old_task
  end

  alias_method :execute_without_bugsnag, :execute
  alias_method :execute, :execute_with_bugsnag
end

Bugsnag.configuration.internal_middleware.use(Bugsnag::Middleware::Rake)
