require './app'

configure_basics

configure_using_environment

add_at_exit

raise RuntimeError.new("Oh no")