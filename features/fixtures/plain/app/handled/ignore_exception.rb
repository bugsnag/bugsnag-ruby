require './app'

class SkippableError < RuntimeError
  attr_accessor :skip_bugsnag
end

begin
  raise SkippableError.new("NotifyException")
rescue => exception
  exception.skip_bugsnag = true
  Bugsnag.notify(exception)
end