require 'resque/tasks'

task 'resque:setup' => :environment do
  # Add a default to run every queue, unless otherwise specified
  ENV['QUEUE'] = '*' unless ENV.include?('QUEUE')

  require './app/workers/resque_worker'
end
