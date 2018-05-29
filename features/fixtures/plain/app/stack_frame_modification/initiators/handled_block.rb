require 'bugsnag'
require './app'

configure_basics

def run(callback)
  step_one(callback)
end

def step_one(callback)
  step_two(callback)
end

def step_two(callback)
  step_three(callback)
end

def step_three(callback)
  crash(callback)
end

def crash(callback)
  Bugsnag.notify(RuntimeError.new("Oh no"), &callback)
end