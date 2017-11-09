require 'shoryuken'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'YOUR_API_KEY'
end

class BugsnagTest
  include Shoryuken::Worker

  shoryuken_options queue: 'connector_development_default', auto_delete: true

  def perform(sqs_msg, body)
    puts "Received message: #{body}"
    raise 'Uh oh!'
  end
end
