if ENV['GEMSETS'] and ENV['GEMSETS'].include? "coverage"
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'bugsnag'

require 'webmock/rspec'
require 'rspec/expectations'
require 'rspec/mocks'

class BugsnagTestException < RuntimeError
  attr_accessor :skip_bugsnag
end

def get_event_from_payload(payload)
  expect(payload["events"].size).to eq(1)
  payload["events"].first
end

def get_headers_from_payload(payload)

end

def get_exception_from_payload(payload)
  event = get_event_from_payload(payload)
  expect(event["exceptions"].size).to eq(1)
  event["exceptions"].last
end

def notify_test_exception(*args)
  Bugsnag.notify(RuntimeError.new("test message"), *args)
end

def ruby_version_greater_equal?(version)
  current_version = RUBY_VERSION.split "."
  target_version = version.split "."
  (Integer(current_version[0]) >= Integer(target_version[0])) &&
    (Integer(current_version[1]) >= Integer(target_version[1])) &&
    (Integer(current_version[2]) >= Integer(target_version[2]))
end

RSpec.configure do |config|
  config.order = "random"

  config.before(:each) do
    WebMock.stub_request(:post, "https://notify.bugsnag.com/")
    WebMock.stub_request(:post, "https://sessions.bugsnag.com/")

    Bugsnag.instance_variable_set(:@configuration, Bugsnag::Configuration.new)
    Bugsnag.configure do |bugsnag|
      bugsnag.api_key = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
      bugsnag.release_stage = "production"
      bugsnag.delivery_method = :synchronous
      # silence logger in tests
      bugsnag.logger = Logger.new(StringIO.new)
    end
  end

  config.after(:each) do
    Bugsnag.configuration.clear_request_data
  end
end

def have_sent_sessions(&matcher)
  have_requested(:post, "https://sessions.bugsnag.com/").with do |request|
    if matcher
      matcher.call([JSON.parse(request.body), request.headers])
      true
    else
      raise "no matcher provided to have_sent_sessions (did you use { })"
    end
  end
end

def have_sent_notification(&matcher)
  have_requested(:post, "https://notify.bugsnag.com/").with do |request|
    if matcher
      matcher.call([JSON.parse(request.body), request.headers])
      true
    else
      raise "no matcher provided to have_sent_notification (did you use { })"
    end
  end
end
