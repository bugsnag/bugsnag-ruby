require 'bugsnag'

class BugsnagTestException < RuntimeError; end

def get_event_from_payload(payload)
  expect(payload[:events].size).to eq(1)
  payload[:events].first
end

def get_exception_from_payload(payload)
  event = get_event_from_payload(payload)
  expect(event[:exceptions].size).to eq(1)
  event[:exceptions].last
end

RSpec.configure do |config|
  config.order = "random"
  
  config.before(:each) do
    Bugsnag.instance_variable_set(:@configuration, Bugsnag::Configuration.new)
    Bugsnag.configure do |config|
      config.api_key = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
      config.release_stage = "production"
      # silence logger in tests
      config.logger = Logger.new(StringIO.new)
    end
  end
  
  config.after(:each) do
    Bugsnag.configuration.clear_request_data
  end
end
