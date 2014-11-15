module Bugsnag
  module Delivery
    class << self
      def register(name, delivery_method)
        delivery_methods[name.to_sym] = delivery_method
      end

      def [](name)
        delivery_methods[name.to_sym]
      end

      private
      def delivery_methods
        @delivery_methods ||= {}
      end
    end
  end
end
