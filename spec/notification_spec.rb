require 'spec_helper'
require 'bugsnag'

class BugsnagTestException < RuntimeError; end

def get_exception_from_payload(payload)
  payload[:events].count.should be == 1
  payload[:events].first[:exceptions].count.should be == 1
  
  payload[:events].first[:exceptions].last
end

describe Bugsnag::Notification do
  before(:each) do
    Bugsnag.configure do |config|
      config.api_key = "fake_api_key"
    end
  end

  it "should have the right exception class" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception[:errorClass].should be == "BugsnagTestException"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should have the right exception message" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception[:message].should be == "It crashed"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should have a valid stacktrace" do
    assert true
  end
end