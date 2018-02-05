module Bugsnag::Middleware
  class IgnoreErrorClass

    ##
    # Determines if the exception should be ignored.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      ignore_error_class = report.raw_exceptions.any? do |ex|
        ancestor_chain = ex.class.ancestors.select { |ancestor| ancestor.is_a?(Class) }.to_set

        report.configuration.ignore_classes.any? do |to_ignore|
          to_ignore.is_a?(Proc) ? to_ignore.call(ex) : ancestor_chain.include?(to_ignore)
        end
      end

      report.ignore! if ignore_error_class

      @bugsnag.call(report)
    end
  end
end
