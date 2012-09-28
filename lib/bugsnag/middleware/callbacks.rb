module Bugsnag::Middleware
  class Callbacks
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(request_data, exceptions, notification)
      if request_data[:before_callbacks]
        request_data[:before_callbacks].each {|c| c.call(*[notification, exceptions][0...c.arity]) }
      end

      @bugsnag.call(request_data, exceptions, notification)

      if request_data[:after_callbacks]
        request_data[:after_callbacks].each {|c| c.call(*[notification, exceptions][0...c.arity]) }
      end
    end
  end
end
