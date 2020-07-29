require 'resque/tasks'

task 'resque:setup' => :environment do
  require './app/workers/resque_worker'
end
