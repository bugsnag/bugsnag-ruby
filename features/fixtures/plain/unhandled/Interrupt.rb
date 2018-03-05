require './app'

configure_basics
add_at_exit

this_process = IO.popen("lessc #{file} --watch")
pid= this_process.pid
Process.kill("INT", pid)