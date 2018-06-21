require 'bugsnag'
require './app'

configure_basics
add_at_exit

def run(callback)
  Bugsnag.before_notify_callbacks << callback

  raise RuntimeError.new "Oh no"
end