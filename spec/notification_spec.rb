require 'spec_helper'
require 'securerandom'

module ActiveRecord; class RecordNotFound < RuntimeError; end; end
class NestedException < StandardError; attr_accessor :original_exception; end
class BugsnagTestExceptionWithMetaData < Exception; include Bugsnag::MetaData; end

describe Bugsnag::Notification do
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

  it "should accept meta data from an exception that mixes in Bugsnag::MetaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:some_tab].should_not be_nil
      event[:metaData][:some_tab][:info].should be == "here"
      event[:metaData][:some_tab][:data].should be == "also here"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception)
  end
  
  it "should accept meta data from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:some_tab].should_not be_nil
      event[:metaData][:some_tab][:info].should be == "overridden"
      event[:metaData][:some_tab][:data].should be == "also here"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception, {:some_tab => {:info => "overridden"}})
  end
  
  it "should accept user_id from an exception that mixes in Bugsnag::MetaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:userId].should be == "exception_user_id"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception)
  end
  
  it "should accept user_id from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:userId].should be == "override_user_id"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception, {:user_id => "override_user_id"})
  end
  
  it "should accept context from an exception that mixes in Bugsnag::MetaData" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:context].should be == "exception_context"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception)
  end
  
  it "should accept context from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:context].should be == "override_context"
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception, {:context => "override_context"})
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
    Bugsnag::Notification.should_receive(:post) do |endpoint, opts|
      # Truncated body should be no bigger than
      # 2 truncated hashes (4096*2) + rest of payload (5000)
      opts[:body].length.should be < 4096*2 + 5000
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :meta_data => {
        :some_tab => {
          :giant => SecureRandom.hex(500_000/2),
          :mega => SecureRandom.hex(500_000/2)
        }
      }
    })
  end

  it "should accept a context in overrides" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:context].should be == "test_context"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :context => "test_context"
    })
  end

  it "should accept a user_id in overrides" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:userId].should be == "test_user"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :user_id => "test_user"
    })
  end

  it "should not send a notification if auto_notify is false" do
    Bugsnag.configure do |config|
      config.auto_notify = false
    end

    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))
  end

  it "should contain a release_stage" do
    Bugsnag.configure do |config|
      config.release_stage = "production"
    end

    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:releaseStage].should be == "production"
    end

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))
  end

  it "should respect the notify_release_stages setting by not sending in development" do
    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

    Bugsnag.configuration.notify_release_stages = ["production"]
    Bugsnag.configuration.release_stage = "development"
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should respect the notify_release_stages setting when set" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
    end

    Bugsnag.configuration.release_stage = "development"
    Bugsnag.configuration.notify_release_stages = ["development"]
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should use the http://notify.bugsnag.com endpoint by default" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      endpoint.should be == "http://notify.bugsnag.com"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should use ssl when use_ssl is true" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      endpoint.should start_with "https://"
    end

    Bugsnag.configuration.use_ssl = true
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should not use ssl when use_ssl is false" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      endpoint.should start_with "http://"
    end

    Bugsnag.configuration.use_ssl = false
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should not use ssl when use_ssl is unset" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      endpoint.should start_with "http://"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should not mark the top-most stacktrace line as inProject if out of project" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception[:stacktrace].should have_at_least(1).items
      exception[:stacktrace].first[:inProject].should be_nil
    end

    Bugsnag.configuration.project_root = "/Random/location/here"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should mark the top-most stacktrace line as inProject if necessary" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      exception[:stacktrace].should have_at_least(1).items
      exception[:stacktrace].first[:inProject].should be == true
    end

    Bugsnag.configuration.project_root = File.expand_path File.dirname(__FILE__)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should add app_version to the payload if it is set" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:appVersion].should be == "1.1.1"
    end

    Bugsnag.configuration.app_version = "1.1.1"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "should filter params from all payload hashes if they are set in default params_filters" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData].should_not be_nil
      event[:metaData][:request].should_not be_nil
      event[:metaData][:request][:params].should_not be_nil
      event[:metaData][:request][:params][:password].should be == "[FILTERED]"
      event[:metaData][:request][:params][:other_password].should be == "[FILTERED]"
      event[:metaData][:request][:params][:other_data].should be == "123456"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "12345", :other_data => "123456"}}})
  end

  it "should filter params from all payload hashes if they are added to params_filters" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData].should_not be_nil
      event[:metaData][:request].should_not be_nil
      event[:metaData][:request][:params].should_not be_nil
      event[:metaData][:request][:params][:password].should be == "[FILTERED]"
      event[:metaData][:request][:params][:other_password].should be == "[FILTERED]"
      event[:metaData][:request][:params][:other_data].should be == "[FILTERED]"
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

  it "should not notify if the exception is matched by an ignore_classes lambda function" do
    Bugsnag.configuration.ignore_classes << lambda {|e| e.message =~ /crashed/}

    Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))
  end

  it "should not unwrap the same exception twice" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:exceptions].should have(1).items
    end

    ex = NestedException.new("Self-referential exception")
    ex.original_exception = ex

    Bugsnag.notify_or_ignore(ex)
  end

  it "should not unwrap more than 5 exceptions" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:exceptions].should have(5).items
    end

    first_ex = ex = NestedException.new("Deep exception")
    10.times do |idx|
      ex = ex.original_exception = NestedException.new("Deep exception #{idx}")
    end

    Bugsnag.notify_or_ignore(first_ex)
  end
end
