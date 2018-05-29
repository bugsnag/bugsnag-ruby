require './app'

configure_basics
add_at_exit

def call_block
  yield 50
end

call_block