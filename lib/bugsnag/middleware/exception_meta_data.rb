module Bugsnag::Middleware
  class ExceptionMetaData
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      # Apply the user's information attached to the exceptions
      report.exceptions.each do |exception|
        if exception.class.include?(Bugsnag::MetaData)
          if exception.bugsnag_user_id.is_a?(String)
            report.user = {id: exception.bugsnag_user_id}
          end
          if exception.bugsnag_context.is_a?(String)
            report.context = exception.bugsnag_context
          end
        end
      end

      @bugsnag.call(report)
    end
  end
end
