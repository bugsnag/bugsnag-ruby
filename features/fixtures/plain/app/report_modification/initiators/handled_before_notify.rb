require 'bugsnag'
require './app'

configure_basics

def run(callback)
  Bugsnag.before_notify_callbacks << callback

  Bugsnag.notify(RuntimeError.new("Oh no"))
end