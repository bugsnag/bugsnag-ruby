module Bugsnag
  # @!attribute error_class
  #   @return [String] the error's class name
  # @!attribute error_message
  #   @return [String] the error's message
  # @!attribute stacktrace
  #   @return [Hash] the error's processed stacktrace
  # @!attribute type
  #   @return [String] the type of error (always "ruby")
  Error = Struct.new(:error_class, :error_message, :stacktrace, :type)
end
