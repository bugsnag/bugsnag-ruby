require 'pg'
require 'que'
require 'socket'
require 'bugsnag'
require 'active_record'

QUE_VERSION = ENV.fetch("QUE_VERSION")

Bugsnag.configure do |config|
  puts "Configuring `api_key` to #{ENV['BUGSNAG_API_KEY']}"
  config.api_key = ENV['BUGSNAG_API_KEY']
  puts "Configuring `endpoint` to #{ENV['BUGSNAG_ENDPOINT']}"
  config.endpoint = ENV['BUGSNAG_ENDPOINT']
end

postgres_ready = false
attempts = 0
MAX_ATTEMPTS = 10

until postgres_ready || attempts >= MAX_ATTEMPTS
  begin
    Timeout::timeout(5) { TCPSocket.new('postgres', 5432).close }

    postgres_ready = true
  rescue Exception
    attempts += 1
    sleep 1
  end
end

raise 'postgres was not ready in time!' unless postgres_ready

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'postgres',
  username: 'postgres',
  password: 'test_password',
  host: 'postgres'
)

Que.connection = ActiveRecord
Que.migrate!(version: Que::Migrations::CURRENT_VERSION)

# Workaround a bug in que/pg
# see https://github.com/que-rb/que/issues/247
if QUE_VERSION == '0.14'
  Que::Adapters::Base::CAST_PROCS[1184] = lambda do |value|
    case value
    when Time then value
    when String then Time.parse(value)
    else raise "Unexpected time class: #{value.class} (#{value.inspect})"
    end
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
