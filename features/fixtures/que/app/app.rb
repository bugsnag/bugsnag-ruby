require 'pg'
require 'que'
require 'bugsnag'
require 'active_record'

Bugsnag.configure do |config|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  config.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
end

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'postgres',
  username: 'postgres',
  password: 'test_password',
  host: 'postgres'
)

Que.connection = ActiveRecord
Que.migrate!(version: 3)

class UnhandledJob < Que::Job
  def run
    raise RuntimeError.new("Unhandled error")
  end

  def handle_error(error)
    destroy
  end
end

class HandledJob < Que::Job
  def run
    raise RuntimeError.new("Handled error")
  rescue => exception
    Bugsnag.notify(exception)
  end
end

case ARGV[0]
when "unhandled"
  UnhandledJob.enqueue
when "handled"
  HandledJob.enqueue
end
