#!/usr/bin/env ruby
require_relative '../app'

configure_basics

def call_block
  yield 50
end

call_block
