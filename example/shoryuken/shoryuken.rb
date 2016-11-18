require 'shoryuken'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'YOUR BUGSNAG API KEY'
end

Shoryuken.configure_server do |config|
  if defined?(Rails)
    # Replace Rails logger so messages are logged wherever Shoryuken is logging
    # Note: this entire block is only run by the processor, so we don't overwrite
    #       the logger when the app is running as usual.
    Rails.logger = Shoryuken::Logging.logger
  end
end

class PlainOldRuby
  include Shoryuken::Worker

  shoryuken_options queue: 'connector_development_default', auto_delete: true

  def perform(sqs_msg, body)
    puts "Received message: #{body}"
    raise 'Uh oh!'
  end
end

# Start up shoryuken processor via:
#
# bundle exec shoryuken -r ./shoryuken.rb -C ./shoryuken.yml

# Then you can open up console session like so:
#
# export AWS_ACCESS_KEY_ID=ABCDEFG123456789
# export AWS_SECRET_ACCESS_KEY=9876543210ZYX
# export AWS_REGION=ap-southeast-2
#
# irb -r ./shoryuken.rb
#
# where you can then say
# PlainOldRuby.perform_async "hello"
