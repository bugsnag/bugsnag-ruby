#!/usr/bin/env ruby
require_relative '../app'

configure_basics

Process.kill("INT", Process.pid)
