require './app'

configure_basics
add_at_exit

class CustomError < RuntimeError
end

raise CustomError.new "Oh no"