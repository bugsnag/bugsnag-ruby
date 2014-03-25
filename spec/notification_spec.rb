require 'spec_helper'
require 'securerandom'
require 'ostruct'

module ActiveRecord; class RecordNotFound < RuntimeError; end; end
class NestedException < StandardError; attr_accessor :original_exception; end
class BugsnagTestExceptionWithMetaData < Exception; include Bugsnag::MetaData; end

class Ruby21Exception < RuntimeError
  attr_accessor :cause
  def self.raise!(msg)
    e = new(msg)
    e.cause = $!
    raise e
  end
end

describe Bugsnag::Notification do
  def notify_test_exception
    Bugsnag.notify(RuntimeError.new("test message"))
  end

  it "should contain an api_key if one is set" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(payload[:apiKey]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b8")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not notify if api_key is not set" do
    Bugsnag.configuration.api_key = nil

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not notify if api_key is empty" do
    Bugsnag.configuration.api_key = ""

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "lets you override the api_key" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(payload[:apiKey]).to eq("9d84383f9be2ca94902e45c756a9979d")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), :api_key => "9d84383f9be2ca94902e45c756a9979d")
  end

  it "uses the env variable apiKey" do
    ENV["BUGSNAG_API_KEY"] = "c9d60ae4c7e70c4b6c4ebd3e8056d2b9"

    Bugsnag.instance_variable_set(:@configuration, Bugsnag::Configuration.new)
    Bugsnag.configure do |config|
      config.release_stage = "production"
    end

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(payload[:apiKey]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b9")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "has the right exception class" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:errorClass]).to eq("BugsnagTestException")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "has the right exception message" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:message]).to eq("It crashed")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "has a valid stacktrace" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].length).to be > 0
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  # TODO: nested context

  it "accepts tabs in overrides and adds them to metaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:some_tab]).not_to be_nil
      expect(event[:metaData][:some_tab][:info]).to eq("here")
      expect(event[:metaData][:some_tab][:data]).to eq("also here")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    })
  end

  it "accepts non-hash overrides and adds them to the custom tab in metaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:custom]).not_to be_nil
      expect(event[:metaData][:custom][:info]).to eq("here")
      expect(event[:metaData][:custom][:data]).to eq("also here")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :info => "here",
      :data => "also here"
    })
  end

  it "accepts meta data from an exception that mixes in Bugsnag::MetaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:some_tab]).not_to be_nil
      expect(event[:metaData][:some_tab][:info]).to eq("here")
      expect(event[:metaData][:some_tab][:data]).to eq("also here")
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

  it "accepts meta data from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:some_tab]).not_to be_nil
      expect(event[:metaData][:some_tab][:info]).to eq("overridden")
      expect(event[:metaData][:some_tab][:data]).to eq("also here")
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

  it "accepts user_id from an exception that mixes in Bugsnag::MetaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:user][:id]).to eq("exception_user_id")
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception)
  end

  it "accepts user_id from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:user][:id]).to eq("override_user_id")
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception, {:user_id => "override_user_id"})
  end

  it "accepts context from an exception that mixes in Bugsnag::MetaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:context]).to eq("exception_context")
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception)
  end

  it "accept contexts from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:context]).to eq("override_context")
    end

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception, {:context => "override_context"})
  end

  it "accepts meta_data in overrides (for backwards compatibility) and merge it into metaData" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:some_tab]).not_to be_nil
      expect(event[:metaData][:some_tab][:info]).to eq("here")
      expect(event[:metaData][:some_tab][:data]).to eq("also here")
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

  it "truncates large meta_data before sending" do
    expect(Bugsnag::Notification).to receive(:post) do |endpoint, opts|
      # Truncated body should be no bigger than
      # 2 truncated hashes (4096*2) + rest of payload (5000)
      expect(opts[:body].length).to be < 4096*2 + 5000
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

  it "accepts a severity in overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:severity]).to eq("info")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :severity => "info"
    })
  end

  it "defaults to error severity" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:severity]).to eq("error")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not accept a bad severity in overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:severity]).to eq("error")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :severity => "infffo"
    })
  end

  it "autonotifies fatal errors" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:severity]).to eq("fatal")
    end

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))
  end

  it "accepts a context in overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:context]).to eq("test_context")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :context => "test_context"
    })
  end

  it "accepts a user_id in overrides" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:user][:id]).to eq("test_user")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :user_id => "test_user"
    })
  end

  it "does not send a notification if auto_notify is false" do
    Bugsnag.configure do |config|
      config.auto_notify = false
    end

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))
  end

  it "contains a release_stage" do
    Bugsnag.configure do |config|
      config.release_stage = "production"
    end

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:app][:releaseStage]).to eq("production")
    end

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))
  end

  it "respects the notify_release_stages setting by not sending in development" do
    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.configuration.notify_release_stages = ["production"]
    Bugsnag.configuration.release_stage = "development"

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "respects the notify_release_stages setting when set" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
    end

    Bugsnag.configuration.release_stage = "development"
    Bugsnag.configuration.notify_release_stages = ["development"]
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "uses the http://notify.bugsnag.com endpoint by default" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(endpoint).to eq("http://notify.bugsnag.com")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "uses ssl when use_ssl is true" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(endpoint).to start_with "https://"
    end

    Bugsnag.configuration.use_ssl = true
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not use ssl when use_ssl is false" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(endpoint).to start_with "http://"
    end

    Bugsnag.configuration.use_ssl = false
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not use ssl when use_ssl is unset" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      expect(endpoint).to start_with "http://"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "does not mark the top-most stacktrace line as inProject if out of project" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].size).to be >= 1
      expect(exception[:stacktrace].first[:inProject]).to be_nil
    end

    Bugsnag.configuration.project_root = "/Random/location/here"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "marks the top-most stacktrace line as inProject if necessary" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].size).to be >= 1
      expect(exception[:stacktrace].first[:inProject]).to eq(true)
    end

    Bugsnag.configuration.project_root = File.expand_path File.dirname(__FILE__)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "adds app_version to the payload if it is set" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:app][:version]).to eq("1.1.1")
    end

    Bugsnag.configuration.app_version = "1.1.1"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "filters params from all payload hashes if they are set in default params_filters" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData]).not_to be_nil
      expect(event[:metaData][:request]).not_to be_nil
      expect(event[:metaData][:request][:params]).not_to be_nil
      expect(event[:metaData][:request][:params][:password]).to eq("[FILTERED]")
      expect(event[:metaData][:request][:params][:other_password]).to eq("[FILTERED]")
      expect(event[:metaData][:request][:params][:other_data]).to eq("123456")
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "12345", :other_data => "123456"}}})
  end

  it "filters params from all payload hashes if they are added to params_filters" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData]).not_to be_nil
      expect(event[:metaData][:request]).not_to be_nil
      expect(event[:metaData][:request][:params]).not_to be_nil
      expect(event[:metaData][:request][:params][:password]).to eq("[FILTERED]")
      expect(event[:metaData][:request][:params][:other_password]).to eq("[FILTERED]")
      expect(event[:metaData][:request][:params][:other_data]).to eq("[FILTERED]")
    end

    Bugsnag.configuration.params_filters << "other_data"
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
  end

  it "does not filter params from payload hashes if their values are nil" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData]).not_to be_nil
      expect(event[:metaData][:request]).not_to be_nil
      expect(event[:metaData][:request][:params]).not_to be_nil
      expect(event[:metaData][:request][:params]).to have_key(:nil_param)
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:nil_param => nil}}})
  end

  it "does not notify if the exception class is in the default ignore_classes list" do
    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.notify_or_ignore(ActiveRecord::RecordNotFound.new("It crashed"))
  end

  it "does not notify if the non-default exception class is added to the ignore_classes" do
    Bugsnag.configuration.ignore_classes << "BugsnagTestException"

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))
  end

  it "does not notify if the exception is matched by an ignore_classes lambda function" do
    Bugsnag.configuration.ignore_classes << lambda {|e| e.message =~ /crashed/}

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))
  end

  it "does not notify if the user agent is present and matches a regex in ignore_user_agents" do
    Bugsnag.configuration.ignore_user_agents << %r{BugsnagUserAgent}

    expect(Bugsnag::Notification).not_to receive(:deliver_exception_payload)

    ((Thread.current["bugsnag_req_data"] ||= {})[:rack_env] ||= {})["HTTP_USER_AGENT"] = "BugsnagUserAgent"

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))
  end

  it "sends the cause of the exception" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:exceptions].size).to eq(2)
    end

    begin
      begin
        raise "jiminey"
      rescue
        Ruby21Exception.raise! "cricket"
      end
    rescue
      Bugsnag.notify $!
    end
  end

  it "does not unwrap the same exception twice" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:exceptions].size).to eq(1)
    end

    ex = NestedException.new("Self-referential exception")
    ex.original_exception = ex

    Bugsnag.notify_or_ignore(ex)
  end

  it "does not unwrap more than 5 exceptions" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:exceptions].size).to eq(5)
    end

    first_ex = ex = NestedException.new("Deep exception")
    10.times do |idx|
      ex = ex.original_exception = NestedException.new("Deep exception #{idx}")
    end

    Bugsnag.notify_or_ignore(first_ex)
  end

  it "calls to_exception on i18n error objects" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:errorClass]).to eq("BugsnagTestException")
      expect(exception[:message]).to eq("message")
    end

    Bugsnag.notify(OpenStruct.new(:to_exception => BugsnagTestException.new("message")))
  end

  it "generates runtimeerror for non exceptions" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:errorClass]).to eq("RuntimeError")
      expect(exception[:message]).to eq("test message")
    end

    notify_test_exception
  end

  it "supports unix-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
      "/Users/james/app/spec/notification_spec.rb:419",
      "/Some/path/rspec/example.rb:113:in `instance_eval'"
    ])

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].length).to eq(2)

      line = exception[:stacktrace][0]
      expect(line[:file]).to eq("/Users/james/app/spec/notification_spec.rb")
      expect(line[:lineNumber]).to eq(419)
      expect(line[:method]).to be nil

      line = exception[:stacktrace][1]
      expect(line[:file]).to eq("/Some/path/rspec/example.rb")
      expect(line[:lineNumber]).to eq(113)
      expect(line[:method]).to eq("instance_eval")
    end

    Bugsnag.notify(ex)
  end

  it "supports windows-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
      "C:/projects/test/app/controllers/users_controller.rb:13:in `index'",
      "C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb:638:in `block in run_before_filters'"
    ])

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].length).to eq(2)

      line = exception[:stacktrace][0]
      expect(line[:file]).to eq("C:/projects/test/app/controllers/users_controller.rb")
      expect(line[:lineNumber]).to eq(13)
      expect(line[:method]).to eq("index")

      line = exception[:stacktrace][1]
      expect(line[:file]).to eq("C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb")
      expect(line[:lineNumber]).to eq(638)
      expect(line[:method]).to eq("block in run_before_filters")
    end

    Bugsnag.notify(ex)
  end

  it "uses a proxy host if configured" do
    Bugsnag.configure do |config|
      config.proxy_host = "host_name"
    end

    expect(Bugsnag::Notification).to receive(:http_proxy) do |*args|
      expect(args.length).to eq(4)
      expect(args[0]).to eq("host_name")
      expect(args[1]).to eq(nil)
      expect(args[2]).to eq(nil)
      expect(args[3]).to eq(nil)
    end

    notify_test_exception
  end

  it "uses a proxy host/port if configured" do
    Bugsnag.configure do |config|
      config.proxy_host = "host_name"
      config.proxy_port = 1234
    end

    expect(Bugsnag::Notification).to receive(:http_proxy) do |*args|
      expect(args.length).to eq(4)
      expect(args[0]).to eq("host_name")
      expect(args[1]).to eq(1234)
      expect(args[2]).to eq(nil)
      expect(args[3]).to eq(nil)
    end

    notify_test_exception
  end

  it "uses a proxy host/port/user/pass if configured" do
    Bugsnag.configure do |config|
      config.proxy_host = "host_name"
      config.proxy_port = 1234
      config.proxy_user = "user"
      config.proxy_password = "password"
    end

    expect(Bugsnag::Notification).to receive(:http_proxy) do |*args|
      expect(args.length).to eq(4)
      expect(args[0]).to eq("host_name")
      expect(args[1]).to eq(1234)
      expect(args[2]).to eq("user")
      expect(args[3]).to eq("password")
    end

    notify_test_exception
  end

  it "sets the timeout time to the value in the configuration" do 
    Bugsnag.configure do |config|
      config.timeout = 10
    end

    expect(Bugsnag::Notification).to receive(:default_timeout) do |*args|
      expect(args.length).to eq(1)
      expect(args[0]).to eq(10)
    end

    notify_test_exception
  end
end
