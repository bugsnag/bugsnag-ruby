require './app'
require './exception_data/crash'

configure_basics

begin
  exception_with_user_id
rescue => exception
  Bugsnag.notify(exception)
end