#!/usr/bin/env ruby
require_relative '../app'

configure_basics

class CustomError < RuntimeError
end

raise CustomError.new "Oh no"
