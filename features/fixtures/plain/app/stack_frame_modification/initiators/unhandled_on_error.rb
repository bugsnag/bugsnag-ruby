require 'bugsnag'
require './app'

configure_basics
add_at_exit

def run(callback)
  Bugsnag.add_on_error(callback)
  step_one
end

def step_one
  step_two
end

def step_two
  step_three
end

def step_three
  crash
end

def crash
  raise RuntimeError.new "Oh no"
end
