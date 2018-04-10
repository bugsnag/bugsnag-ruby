require './app'

configure_basics

configure_using_environment

Bugsnag.notify(RuntimeError.new("Oh no"))