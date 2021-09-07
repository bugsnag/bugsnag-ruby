module Bugsnag
  # @!attribute error_class
  #   @return [String] the error's class name
  # @!attribute error_message
  #   @return [String] the error's message
  # @!attribute type
  #   @return [String] the type of error (always "ruby")
  Error = Struct.new(:error_class, :error_message, :type)
end
