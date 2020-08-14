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

# Workaround a bug in que/pg
# see https://github.com/que-rb/que/issues/247
Que::Adapters::Base::CAST_PROCS[1184] = lambda do |value|
  case value
  when Time then value
  when String then Time.parse(value)
  else raise "Unexpected time class: #{value.class} (#{value.inspect})"
  end
end

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
