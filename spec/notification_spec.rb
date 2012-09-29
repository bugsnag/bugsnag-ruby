require 'spec_helper'
require 'bugsnag'

class BugsnagTestException < RuntimeError; end

def get_event_from_payload(payload)
  payload[:events].count.should be == 1
  payload[:events].first
end

def get_exception_from_payload(payload)
  event = get_event_from_payload(payload)
  event[:exceptions].count.should be == 1
  event[:exceptions].last
end

describe Bugsnag::Notification do
  before(:each) do
    Bugsnag.configure do |config|
      config.api_key = "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
    end
  end

  it "should contain an api_key if one is set" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      payload[:apiKey].should be == "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should not notify if api_key is not set" do
    Bugsnag.configuration.api_key = nil

    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should not notify if api_key is empty" do
    Bugsnag.configuration.api_key = ""

    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
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
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception[:stacktrace].length.should be > 0
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should accept tabs in overrides and add them to metaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:some_tab].should_not be_nil
      event[:metaData][:some_tab][:info].should be == "here"
      event[:metaData][:some_tab][:data].should be == "also here"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    })
  end
  
  it "should accept non-hash overrides and add them to the custom tab in metaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:custom].should_not be_nil
      event[:metaData][:custom][:info].should be == "here"
      event[:metaData][:custom][:data].should be == "also here"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :info => "here",
      :data => "also here"
    })
  end

  it "should accept meta_data in overrides (for backwards compatibility) and merge it into metaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:some_tab].should_not be_nil
      event[:metaData][:some_tab][:info].should be == "here"
      event[:metaData][:some_tab][:data].should be == "also here"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :meta_data => {
        :some_tab => {
          :info => "here",
          :data => "also here"
        }
      }
    })
  end

  it "should truncate large meta_data before sending" do
    raise "fail"
  end

  it "should convert or strip json-unsafe metadata" do
    raise "fail"
  end

  it "should accept a context in overrides" do
    raise "fail"
  end
  
  it "should accept a user_id in overrides" do
    raise "fail"
  end
  
  it "should not send a notification if auto_notify is false" do
    raise "fail"
  end

  it "should contain a release_stage" do
    raise "fail"
  end

  it "should respect the notify_release_stages setting" do
    raise "fail"
  end

  it "should use ssl when use_ssl is true" do
    raise "fail"
  end

  it "should mark the top-most stacktrace line as inProject if necessary" do
    raise "fail"
  end

  it "should add app_version to the payload if it is set" do
    raise "fail"
  end

  it "should filter params from all payload hashes if they are set in params_filters" do
    raise "fail"
  end

  it "should not notify if the exception class is in the default ignore_classes list" do
    raise "fail"
  end

  it "should not notify if the non-default exception class is added to the ignore_classes" do
    raise "fail"
  end
end