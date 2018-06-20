require './app'
require './exception_data/crash'

configure_basics

begin
  exception_with_meta_data
rescue => exception
  Bugsnag.notify(exception)
end