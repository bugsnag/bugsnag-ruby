module Bugsnag::Rails
  class FilteredRequest

    def initialize(controller)
      @controller = controller
      @request    = controller.__send__(:request)
    end

    # Rails 2 does parameter filtering via a dynamically-defined method on the
    # controller. For this reason, these parameters are not accessible to the
    # Bugsnag configuration and the filtering must be done while we still have
    # the controller object.
    #
    def parameters
      @parameters ||= if @controller.respond_to?(:filter_parameters)
                        @controller.__send__(:filter_parameters, @request.parameters)
                      else
                        @request.parameters
                      end
    end

    # Delegate everything else to the underlying request object.
    #
    def respond_to?(method, include_private = false)
      @request.respond_to?(method, include_private) || super
    end

    def method_missing(method, *args, &block)
      if @request.respond_to?(method)
        @request.__send__(method, *args, &block)
      else
        super
      end
    end

  end
end