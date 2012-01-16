module Bugsnag
  class Resque
    def self.perform(*args)
      puts "performing #{args.inspect}"
    end
  end
end

Bugsnag::Notification.class_eval do
  def deliver_exception_payload_with_resque(*args)
    Resque.enqueue(Bugsnag::Resque, *args)
    puts "delivering with resque"
  end
  
  alias_method :deliver_exception_payload_without_resque, :deliver_exception_payload
  alias_method :deliver_exception_payload, :deliver_exception_payload_with_resque
end