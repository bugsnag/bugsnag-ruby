require 'spec_helper'
require 'bugsnag'

module ActiveRecord; class RecordNotFound < RuntimeError; end; end
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
  end

  it "should accept hash overrides and add them to metadata" do
  end
  
  it "should accept non-hash overrides and add them to custom metadata" do
  end

  it "should accept meta_data in overrides and merge it into overrides" do
  end
  
  it "should accept a context in overrides" do
  end
  
  it "should accept a user_id in overrides" do
  end
  
  it "should not send a notification if auto_notify is false" do
  end

  it "should contain a release_stage" do
  end

  it "should respect the notify_release_stages setting" do
  end

  it "should use ssl when use_ssl is true" do
  end

  it "should mark the top-most stacktrace line as inProject if necessary" do
  end

  it "should add app_version to the payload if it is set" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception.should_not be_nil
      payload[:events].first[:appVersion].should be == "1.1.1"
    end
    
    Bugsnag.configuration.app_version = "1.1.1"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should filter params from all payload hashes if they are set in default params_filters" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      payload[:events].should_not be_nil
      payload[:events].first[:metaData].should_not be_nil
      payload[:events].first[:metaData][:request].should_not be_nil
      payload[:events].first[:metaData][:request][:params].should_not be_nil
      payload[:events].first[:metaData][:request][:params][:password].should be == "[FILTERED]"
      payload[:events].first[:metaData][:request][:params][:other_password].should be == "[FILTERED]"
      payload[:events].first[:metaData][:request][:params][:other_data].should be == "123456"
    end
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "12345", :other_data => "123456"}}})
  end
  
  it "should filter params from all payload hashes if they are added to params_filters" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      payload[:events].should_not be_nil
      payload[:events].first[:metaData].should_not be_nil
      payload[:events].first[:metaData][:request].should_not be_nil
      payload[:events].first[:metaData][:request][:params].should_not be_nil
      payload[:events].first[:metaData][:request][:params][:password].should be == "[FILTERED]"
      payload[:events].first[:metaData][:request][:params][:other_password].should be == "[FILTERED]"
      payload[:events].first[:metaData][:request][:params][:other_data].should be == "[FILTERED]"
    end
    
    Bugsnag.configuration.params_filters << "other_data"
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
  end

  it "should not notify if the exception class is in the default ignore_classes list" do
    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)
    
    Bugsnag.notify_or_ignore(ActiveRecord::RecordNotFound.new("It crashed"))
  end

  it "should not notify if the non-default exception class is added to the ignore_classes" do
    Bugsnag.configuration.ignore_classes << "BugsnagTestException"
    
    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)
    
    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))
  end
end