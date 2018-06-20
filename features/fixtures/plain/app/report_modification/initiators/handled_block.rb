require 'bugsnag'
require './app'

configure_basics

def run(callback)
  Bugsnag.notify(RuntimeError.new("Oh no"), &callback)
end