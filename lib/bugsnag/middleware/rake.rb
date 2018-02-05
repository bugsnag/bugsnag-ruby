module Bugsnag::Middleware
  class Rake
    ##
    # Extracts and attaches rake data to the request.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      task = report.request_data[:bugsnag_running_task]

      if task
        report.add_tab(:rake_task, {
          :name => task.name,
          :description => task.full_comment,
          :arguments => task.arg_description
        })

        report.context ||= task.name
      end

      @bugsnag.call(report)
    end
  end
end
