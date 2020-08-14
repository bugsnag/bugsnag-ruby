require 'mailman'
require_relative 'config/environment.rb'

Mailman.config.ignore_stdin = false

Mailman::Application.run do
  default do
    raise 'emails'
  end
end
