module Bugsnag
  module Breadcrumbs
    class Recorder < Array
      MAX_ITEMS = 25
      def initialize
        @lock = Mutex.new
      end

      def add_breadcrumb(breadcrumb)
        @lock.synchronize do
          self.push(breadcrumb)
          if self.length > MAX_ITEMS
            self.shift(self.length - MAX_ITEMS)
          end
        end
      end
    end
  end
end