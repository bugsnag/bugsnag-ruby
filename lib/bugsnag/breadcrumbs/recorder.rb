module Bugsnag
  module Breadcrumbs
    class Recorder < Array
      MAX_ITEMS = 25
      def add_breadcrumb(breadcrumb)
        push(breadcrumb)
        shift(length - MAX_ITEMS) if length > MAX_ITEMS
      end
    end
  end
end
