require 'thread'

module Bugsnag
  class Queue < ::Queue
    MAX_OUTSTANDING_REQUESTS = 100
    STOP = Object.new

    def push(*)
      if length > MAX_OUTSTANDING_REQUESTS
        Bugsnag.warn("Dropping notification, #{length} outstanding requests")
        return
      end
      @thread ||= create_processor
      super
    end

    private

    def create_processor
      t = Thread.new do
        while x = pop
          break if x == STOP
          x.call
        end
      end

      at_exit do
        Bugsnag.warn("Waiting for #{length} outstanding request(s)") unless empty?
        push STOP
        t.join
      end
    end
  end
end
