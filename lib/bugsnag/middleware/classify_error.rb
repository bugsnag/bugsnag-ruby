module Bugsnag::Middleware
  class ClassifyError
    INFO_CLASSES = [
        "AbstractController::ActionNotFound",
        "ActionController::InvalidAuthenticityToken",
        "ActionController::ParameterMissing",
        "ActionController::UnknownAction",
        "ActionController::UnknownFormat",
        "ActionController::UnknownHttpMethod",
        "ActiveRecord::RecordNotFound",
        "CGI::Session::CookieStore::TamperedWithCookie",
        "Mongoid::Errors::DocumentNotFound",
        "SignalException",
        "SystemExit"
    ]

    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(notification)
      notification.exceptions.each do |ex|

        outer_break = false

        ancestor_chain = ex.class.ancestors.select {
          |ancestor| ancestor.is_a?(Class) 
        }.map {
          |ancestor| ancestor.to_s
        }

        INFO_CLASSES.each do |info_class|
          if ancestor_chain.include?(info_class)
            notification.severity_reason = {
              :type => Bugsnag::Notification::ERROR_CLASS,
              :attributes => {
                :errorClass => info_class
              }
            }
            notification.severity = 'info'
            outer_break = true
            break
          end
        end

        break if outer_break
      end

      @bugsnag.call(notification)
    end
  end
end
    