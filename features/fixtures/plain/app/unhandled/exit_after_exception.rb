#!/usr/bin/env ruby
require_relative '../app'

configure_basics

begin
  raise 'oh no'
rescue
  exit
end
