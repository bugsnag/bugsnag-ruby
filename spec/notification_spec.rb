# encoding: utf-8
require 'spec_helper'
require 'securerandom'
require 'ostruct'

module ActiveRecord; class RecordNotFound < RuntimeError; end; end
class NestedException < StandardError; attr_accessor :original_exception; end
class BugsnagTestExceptionWithMetaData < Exception; include Bugsnag::MetaData; end
class BugsnagSubclassTestException < BugsnagTestException; end

class Ruby21Exception < RuntimeError
  attr_accessor :cause
  def self.raise!(msg)
    e = new(msg)
    e.cause = $!
    raise e
  end
end

class JRubyException
  def self.raise!
    new.gloops
  end

  def gloops
    java.lang.System.out.printf(nil)
  end
end

describe Bugsnag::Notification do
  it "should contain an api_key if one is set" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      expect(payload["apiKey"]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b8")
    }
  end

  it "does not notify if api_key is not set" do
    Bugsnag.configuration.api_key = nil

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if api_key is empty" do
    Bugsnag.configuration.api_key = ""

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "lets you override the api_key" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), :api_key => "9d84383f9be2ca94902e45c756a9979d")

    expect(Bugsnag).to have_sent_notification{ |payload|
      expect(payload["apiKey"]).to eq("9d84383f9be2ca94902e45c756a9979d")
    }
  end

  it "lets you override the groupingHash" do

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:grouping_hash => "this is my grouping hash"})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["groupingHash"]).to eq("this is my grouping hash")
    }
  end

  it "uses the env variable apiKey" do
    ENV["BUGSNAG_API_KEY"] = "c9d60ae4c7e70c4b6c4ebd3e8056d2b9"

    Bugsnag.instance_variable_set(:@configuration, Bugsnag::Configuration.new)
    Bugsnag.configure do |config|
      config.release_stage = "production"
      config.delivery_method = :synchronous
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      expect(payload["apiKey"]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b9")
    }
  end

  it "has the right exception class" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["errorClass"]).to eq("BugsnagTestException")
    }
  end

  it "has the right exception message" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["message"]).to eq("It crashed")
    }
  end

  it "has a valid stacktrace" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].length).to be > 0
    }
  end

  # TODO: nested context

  it "accepts tabs in overrides and adds them to metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "accepts non-hash overrides and adds them to the custom tab in metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :info => "here",
      :data => "also here"
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "accepts meta data from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "accepts meta data from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception, {:some_tab => {:info => "overridden"}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "overridden",
        "data" => "also here"
      )
    }
  end

  it "accepts user_id from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("exception_user_id")
    }
  end

  it "accepts user_id from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception, {:user_id => "override_user_id"})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("override_user_id")
    }
  end

  it "accepts context from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("exception_context")
    }
  end

  it "accept contexts from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception, {:context => "override_context"})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("override_context")
    }
  end

  it "accepts meta_data in overrides (for backwards compatibility) and merge it into metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :meta_data => {
        :some_tab => {
          :info => "here",
          :data => "also here"
        }
      }
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "truncates large meta_data before sending" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :meta_data => {
        :some_tab => {
          :giant => SecureRandom.hex(500_000/2),
          :mega => SecureRandom.hex(500_000/2)
        }
      }
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      # Truncated body should be no bigger than
      # 2 truncated hashes (4096*2) + rest of payload (20000)
      expect(::JSON.dump(payload).length).to be < 4096*2 + 20000
    }
  end

  it "accepts a severity in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :severity => "info"
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("info")
    }

  end

  it "defaults to warning severity" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("warning")
    }
  end

  it "does not accept a bad severity in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :severity => "fatal"
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("warning")
    }
  end

  it "autonotifies errors" do
    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("error")
    }
  end


  it "accepts a context in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :context => "test_context"
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("test_context")
    }
  end

  it "accepts a user_id in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :user_id => "test_user"
    })

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("test_user")
    }
  end

  it "does not send a notification if auto_notify is false" do
    Bugsnag.configure do |config|
      config.auto_notify = false
    end

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "contains a release_stage" do
    Bugsnag.configure do |config|
      config.release_stage = "production"
    end

    Bugsnag.auto_notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["app"]["releaseStage"]).to eq("production")
    }
  end

  it "respects the notify_release_stages setting by not sending in development" do
    Bugsnag.configuration.notify_release_stages = ["production"]
    Bugsnag.configuration.release_stage = "development"

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "respects the notify_release_stages setting when set" do
    Bugsnag.configuration.release_stage = "development"
    Bugsnag.configuration.notify_release_stages = ["development"]
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].length).to eq(1)
    }
  end

  it "uses the https://notify.bugsnag.com endpoint by default" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(WebMock).to have_requested(:post, "https://notify.bugsnag.com")
  end

  it "uses ssl when use_ssl is true" do
    Bugsnag.configuration.use_ssl = true
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(WebMock).to have_requested(:post, "https://notify.bugsnag.com")
  end

  it "does not use ssl when use_ssl is false" do
    stub_request(:post, "http://notify.bugsnag.com/")
    Bugsnag.configuration.use_ssl = false
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(WebMock).to have_requested(:post, "http://notify.bugsnag.com")
  end

  it "uses ssl when use_ssl is unset" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(WebMock).to have_requested(:post, "https://notify.bugsnag.com")
  end

  it "does not mark the top-most stacktrace line as inProject if out of project" do
    Bugsnag.configuration.project_root = "/Random/location/here"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].size).to be >= 1
      expect(exception["stacktrace"].first["inProject"]).to be_nil
    }
  end

  it "does not mark the top-most stacktrace line as inProject if it matches a vendor path" do
    Bugsnag.configuration.project_root = File.expand_path('../../', __FILE__)
    Bugsnag.configuration.vendor_paths = [File.expand_path('../', __FILE__)]

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].size).to be >= 1
      expect(exception["stacktrace"].first["inProject"]).to be_nil
    }
  end

  it "marks the top-most stacktrace line as inProject if necessary" do
    Bugsnag.configuration.project_root = File.expand_path File.dirname(__FILE__)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].size).to be >= 1
      expect(exception["stacktrace"].first["inProject"]).to eq(true)
    }
  end

  it "adds app_version to the payload if it is set" do
    Bugsnag.configuration.app_version = "1.1.1"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["app"]["version"]).to eq("1.1.1")
    }
  end

  it "filters params from all payload hashes if they are set in default params_filters" do

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "12345", :other_data => "123456"}}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("123456")
    }
  end

  it "filters params from all payload hashes if they are added to params_filters" do

    Bugsnag.configuration.params_filters << "other_data"
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
    }
  end

  it "filters params from all payload hashes if they are added to params_filters as regex" do

    Bugsnag.configuration.params_filters << /other_data/
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
    }
  end

  it "filters params from all payload hashes if they are added to params_filters as partial regex" do

    Bugsnag.configuration.params_filters << /r_data/
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
    }
  end

  it "does not filter params from payload hashes if their values are nil" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:request => {:params => {:nil_param => nil}}})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).to have_key("nil_param")
    }
  end

  it "does not notify if the exception class is in the default ignore_classes list" do
    Bugsnag.notify_or_ignore(ActiveRecord::RecordNotFound.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if the non-default exception class is added to the ignore_classes" do
    Bugsnag.configuration.ignore_classes << "BugsnagTestException"

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if exception's ancestor is an ignored class" do
    Bugsnag.configuration.ignore_classes << "BugsnagTestException"

    Bugsnag.notify_or_ignore(BugsnagSubclassTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if any caused exception is an ignored class" do
    Bugsnag.configuration.ignore_classes << "NestedException"

    ex = NestedException.new("Self-referential exception")
    ex.original_exception = BugsnagTestException.new("It crashed")

    Bugsnag.notify_or_ignore(ex)

    expect(Bugsnag).not_to have_sent_notification
  end

  it "accepts both String and Class instances as an ignored class" do
    Bugsnag.configuration.ignore_classes << BugsnagTestException

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if the user agent is present and matches a regex in ignore_user_agents" do
    Bugsnag.configuration.ignore_user_agents << %r{BugsnagUserAgent}

    ((Thread.current["bugsnag_req_data"] ||= {})[:rack_env] ||= {})["HTTP_USER_AGENT"] = "BugsnagUserAgent"

    Bugsnag.notify_or_ignore(BugsnagTestException.new("It crashed"))

    expect(Bugsnag::Notification).not_to have_sent_notification
  end

  it "sends the cause of the exception" do
    begin
      begin
        raise "jiminey"
      rescue
        Ruby21Exception.raise! "cricket"
      end
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(2)
    }
  end

  it "does not unwrap the same exception twice" do
    ex = NestedException.new("Self-referential exception")
    ex.original_exception = ex

    Bugsnag.notify_or_ignore(ex)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(1)
    }
  end

  it "does not unwrap more than 5 exceptions" do

    first_ex = ex = NestedException.new("Deep exception")
    10.times do |idx|
      ex = ex.original_exception = NestedException.new("Deep exception #{idx}")
    end

    Bugsnag.notify_or_ignore(first_ex)
    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(5)
    }
  end

  it "calls to_exception on i18n error objects" do
    Bugsnag.notify(OpenStruct.new(:to_exception => BugsnagTestException.new("message")))

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["errorClass"]).to eq("BugsnagTestException")
      expect(exception["message"]).to eq("message")
    }
  end

  it "generates runtimeerror for non exceptions" do
    notify_test_exception

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["errorClass"]).to eq("RuntimeError")
      expect(exception["message"]).to eq("test message")
    }
  end

  it "supports unix-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
      "/Users/james/app/spec/notification_spec.rb:419",
      "/Some/path/rspec/example.rb:113:in `instance_eval'"
    ])

    Bugsnag.notify(ex)

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].length).to eq(2)

      line = exception["stacktrace"][0]
      expect(line["file"]).to eq("/Users/james/app/spec/notification_spec.rb")
      expect(line["lineNumber"]).to eq(419)
      expect(line["method"]).to be nil

      line = exception["stacktrace"][1]
      expect(line["file"]).to eq("/Some/path/rspec/example.rb")
      expect(line["lineNumber"]).to eq(113)
      expect(line["method"]).to eq("instance_eval")
    }
  end

  it "supports windows-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
      "C:/projects/test/app/controllers/users_controller.rb:13:in `index'",
      "C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb:638:in `block in run_before_filters'"
    ])

    Bugsnag.notify(ex)

    expect(Bugsnag).to have_sent_notification{ |payload|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].length).to eq(2)

      line = exception["stacktrace"][0]
      expect(line["file"]).to eq("C:/projects/test/app/controllers/users_controller.rb")
      expect(line["lineNumber"]).to eq(13)
      expect(line["method"]).to eq("index")

      line = exception["stacktrace"][1]
      expect(line["file"]).to eq("C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb")
      expect(line["lineNumber"]).to eq(638)
      expect(line["method"]).to eq("block in run_before_filters")
    }
  end

  it "should fix invalid utf8" do
    invalid_data = "fl\xc3ff"
    invalid_data.force_encoding('BINARY') if invalid_data.respond_to?(:force_encoding)

    notify_test_exception(:fluff => {:fluff => invalid_data})

    expect(Bugsnag).to have_sent_notification{ |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/fl�ff/)
      else
        expect(payload.to_json).to match(/flff/)
      end
    }
  end

  it "should handle utf8 encoding errors in exceptions_list" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    begin
      JSON.parse(invalid_data)
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification { |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  it "should handle utf8 encoding errors in notification context" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    begin
      raise
    rescue
      Bugsnag.notify($!, { :context => invalid_data })
    end

    expect(Bugsnag).to have_sent_notification { |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  it "should handle utf8 encoding errors in notification app fields" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    Bugsnag.configuration.app_version = invalid_data
    Bugsnag.configuration.release_stage = invalid_data
    Bugsnag.configuration.app_type = invalid_data

    begin
      raise
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification { |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  it "should handle utf8 encoding errors in grouping_hash" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    Bugsnag.before_notify_callbacks << lambda do |notif|
      notif.grouping_hash = invalid_data
    end

    begin
      raise
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification { |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  it "should handle utf8 encoding errors in notification user fields" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    Bugsnag.before_notify_callbacks << lambda do |notif|
      notif.user = {
        :email => "#{invalid_data}@foo.com",
        :name => invalid_data
      }
    end

    begin
      raise
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification { |payload|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  if defined?(JRUBY_VERSION)

    it "should work with java.lang.Throwables" do
      begin
        JRubyException.raise!
      rescue
        Bugsnag.notify $!
      end

      expect(Bugsnag).to have_sent_notification{ |payload|
        exception = get_exception_from_payload(payload)
        expect(exception["errorClass"]).to eq('Java::JavaLang::ArrayIndexOutOfBoundsException')
        expect(exception["message"]).to eq("2")
        expect(exception["stacktrace"].size).to be > 0
      }
    end
  end
end
