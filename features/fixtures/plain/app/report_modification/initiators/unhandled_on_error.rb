require 'bugsnag'
require './app'

configure_basics
add_at_exit

def run(callback)
  Bugsnag.add_on_error(callback)

  raise RuntimeError.new "Oh no"
end
