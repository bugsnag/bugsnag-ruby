module Bugsnag
  module Delay
    class Resque
      @queue = "bugsnag"
      def self.perform(*args)
        Bugsnag::Notification.deliver_exception_payload_without_resque(*args)
      end
    end
  end
end

Bugsnag::Notification.class_eval do
  class << self
    def deliver_exception_payload_with_resque(*args)
      Resque.enqueue(Bugsnag::Delay::Resque, *args)
    end
  
    alias_method :deliver_exception_payload_without_resque, :deliver_exception_payload
    alias_method :deliver_exception_payload, :deliver_exception_payload_with_resque
  end
end