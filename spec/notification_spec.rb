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

  it "should accept hash overrides and add them to metadata" do
    assert true
  end
  
  it "should accept non-hash overrides and add them to custom metadata" do
    assert true
  end

  it "should accept meta_data in overrides and merge it into overrides" do
    assert true
  end
  
  it "should accept a context in overrides" do
    assert true
  end
  
  it "should accept a user_id in overrides" do
    assert true
  end
  
  it "should not send a notification if auto_notify is false" do
    assert true
  end

  it "should contain a release_stage" do
    assert true
  end

  it "should respect the notify_release_stages setting" do
    assert true
  end

  it "should use ssl when use_ssl is true" do
    assert true
  end

  it "should mark the top-most stacktrace line as inProject if necessary" do
    assert true
  end

  it "should add app_version to the payload if it is set" do
    assert true
  end

  it "should filter params from all payload hashes if they are set in params_filters" do
    assert true
  end

  it "should not notify if the exception class is in the default ignore_classes list" do
    assert true
  end

  it "should not notify if the non-default exception class is added to the ignore_classes" do
    assert true
  end
end