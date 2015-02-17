module Bugsnag::Middleware
  class Rake
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      task = notification.request_data[:bugsnag_running_task]

      if task
        notification.add_tab(:rake_task, {
          :name => task.name,
          :description => task.full_comment,
          :arguments => task.arg_description
        })

        notification.context ||= task.name
      end

      @bugsnag.call(notification)
    end
  end
end
