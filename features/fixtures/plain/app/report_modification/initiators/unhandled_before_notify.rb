require 'bugsnag'
require './app'

configure_basics

def run(callback)
  Bugsnag.before_notify_callbacks << callback

  raise RuntimeError.new "Oh no"
end
