require 'bugsnag'
require './app'

configure_basics

def run(callback)
  Bugsnag.add_on_error(callback)

  Bugsnag.notify(RuntimeError.new("Oh no"))
end
