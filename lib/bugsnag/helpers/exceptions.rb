module Bugsnag
  module Helpers
    MAX_EXCEPTIONS_TO_UNWRAP = 5

    class << self
      ##
      # Generates a list of exceptions
      def generate_raw_exceptions(exception)
        exceptions = []

        ex = exception
        while !ex.nil? && !exceptions.include?(ex) && exceptions.length < MAX_EXCEPTIONS_TO_UNWRAP

          unless ex.is_a? Exception
            if ex.respond_to?(:to_exception)
              ex = ex.to_exception
            elsif ex.respond_to?(:exception)
              ex = ex.exception
            end
          end

          unless ex.is_a?(Exception) || (defined?(Java::JavaLang::Throwable) && ex.is_a?(Java::JavaLang::Throwable))
            Bugsnag.configuration.warn("Converting non-Exception to RuntimeError: #{ex.inspect}")
            ex = RuntimeError.new(ex.to_s)
            ex.set_backtrace caller
          end

          exceptions << ex

          ex = if ex.respond_to?(:cause) && ex.cause
                 ex.cause
               elsif ex.respond_to?(:continued_exception) && ex.continued_exception
                 ex.continued_exception
               elsif ex.respond_to?(:original_exception) && ex.original_exception
                 ex.original_exception
               end
        end

        exceptions
      end
    end
  end
end
