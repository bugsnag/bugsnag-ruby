require "set"

module Bugsnag::Breadcrumbs
  class OnBreadcrumbCallbackList
    def initialize
      @callbacks = Set.new
      @mutex = Mutex.new
    end

    ##
    # @param callback [Proc, Method, #call]
    # @return [void]
    def add(callback)
      @mutex.synchronize do
        @callbacks.add(callback)
      end
    end

    ##
    # @param callback [Proc, Method, #call]
    # @return [void]
    def remove(callback)
      @mutex.synchronize do
        @callbacks.delete(callback)
      end
    end

    ##
    # @param breadcrumb [Breadcrumb]
    # @return [void]
    def call(breadcrumb)
      @callbacks.each do |callback|
        should_continue = callback.call(breadcrumb)

        # only stop if should_continue is explicity 'false' to allow callbacks
        # to return 'nil'
        if should_continue == false
          breadcrumb.ignore!
          break
        end
      end
    end
  end
end
