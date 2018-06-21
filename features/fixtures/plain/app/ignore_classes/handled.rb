require './app'
require './ignore_classes/ignore_error'

begin
  raise IgnoreError.new "Oh no"
rescue => exception
  Bugsnag.notify(exception)
end