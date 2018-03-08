require './app'

configure_basics

begin
  raise RuntimeError.new("NotifyException")
rescue => exception
  Bugsnag.notify(exception)
end
