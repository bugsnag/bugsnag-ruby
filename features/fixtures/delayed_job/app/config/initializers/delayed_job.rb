require 'delayed_job'

Delayed::Worker.max_attempts = 1