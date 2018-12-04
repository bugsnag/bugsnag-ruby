require 'bugsnag'
require './app'

configure_basics

def run(callback)
  Bugsnag.before_notify_callbacks << callback
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
  begin
    "Test".insrt(-1, "!")
  rescue Exception => e
    Bugsnag.notify(e)
  end
end