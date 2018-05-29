require './app'
require './exception_data/crash'

configure_basics

begin
  exception_with_context
rescue => exception
  Bugsnag.notify(exception)
end