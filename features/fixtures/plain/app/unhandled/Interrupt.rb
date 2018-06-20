require './app'

configure_basics
add_at_exit

Process.kill("INT", Process.pid)