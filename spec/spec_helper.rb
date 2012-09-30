require 'bugsnag'

class BugsnagTestException < RuntimeError; end

def get_event_from_payload(payload)
  payload[:events].should have(1).items
  payload[:events].first
end

def get_exception_from_payload(payload)
  event = get_event_from_payload(payload)
  event[:exceptions].should have(1).items
  event[:exceptions].last
end

RSpec.configure do |config|
  config.order = "random"
  
  config.before(:each) do
    Bugsnag.instance_variable_set(:@configuration, Bugsnag::Configuration.new)
    Bugsnag.configure do |config|
      config.api_key = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
    end
  end
end
