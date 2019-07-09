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

describe Bugsnag::Report do
  it "should contain an api_key if one is set" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      expect(headers["Bugsnag-Api-Key"]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b8")
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
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.api_key = "9d84383f9be2ca94902e45c756a9979d"
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      expect(headers["Bugsnag-Api-Key"]).to eq("9d84383f9be2ca94902e45c756a9979d")
    }
  end

  it "lets you override the groupingHash" do

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.grouping_hash = "this is my grouping hash"
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      expect(headers["Bugsnag-Api-Key"]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b9")
    }
  end

  it "has the right exception class" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["errorClass"]).to eq("BugsnagTestException")
    }
  end

  it "has the right exception message" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["message"]).to eq("It crashed")
    }
  end

  it "has a valid stacktrace" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].length).to be > 0
    }
  end

  it "uses correct unhandled defaults" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["unhandled"]).to be false
      expect(event["severity"]).to eq("warning")
      expect(event["severityReason"]).to eq({
        "type" => "handledException"
      })
    }
  end

  it "sets correct severityReason if severity is modified in a block" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |notification|
      notification.severity = "info"
    end
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["unhandled"]).to be false
      expect(event["severity"]).to eq("info")
      expect(event["severityReason"]).to eq({
        "type" => "userCallbackSetSeverity"
      })
    }
  end

  it "sets correct severity and reason for specific error classes" do
    original_ignore_classes = Bugsnag.configuration.ignore_classes

    begin
      # The default ignore_classes includes SignalException, so we need to
      # temporarily set it to something else.
      Bugsnag.configuration.ignore_classes = Set[SystemExit]
      Bugsnag.notify(SignalException.new("TERM"))
      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["unhandled"]).to be false
        expect(event["severity"]).to eq("info")
        expect(event["severityReason"]).to eq({
          "type" => "errorClass",
          "attributes" => {
            "errorClass" => "SignalException"
          }
        })
      }
    ensure
      Bugsnag.configuration.ignore_classes = original_ignore_classes
    end
  end

  # TODO: nested context

  it "accepts tabs in overrides and adds them to metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({
        some_tab: {
          info: "here",
          data: "also here"
        }
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "accepts meta data from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      some_tab: {
        info: "here",
        data: "also here"
      }
    }

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "removes tabs" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception) do |report|
      report.remove_tab(:some_tab)
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to be_nil
    }
  end

  it "ignores removing nil tabs" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_meta_data = {
      :some_tab => {
        :info => "here",
        :data => "also here"
      }
    }

    Bugsnag.notify(exception) do |report|
      report.remove_tab(nil)
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "Creates a custom tab for metadata which is not a Hash" do
    exception = Exception.new("It crashed")

    Bugsnag.notify(exception) do |report|
      report.add_tab(:some_tab, "added")
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).to eq(
        "some_tab" => "added",
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

    Bugsnag.notify(exception) do |report|
      report.add_tab(:some_tab, {:info => "overridden"})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("exception_user_id")
    }
  end

  it "accepts user_id from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_user_id = "exception_user_id"

    Bugsnag.notify(exception) do |report|
      report.user.merge!({:id => "override_user_id"})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("override_user_id")
    }
  end

  it "accepts context from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("exception_context")
    }
  end

  it "accepts grouping_hash from an exception that mixes in Bugsnag::MetaData" do
    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_grouping_hash = "exception_hash"

    Bugsnag.notify(exception)

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["groupingHash"]).to eq("exception_hash")
    }
  end

  it "accept contexts from an exception that mixes in Bugsnag::MetaData, but override using the overrides" do

    exception = BugsnagTestExceptionWithMetaData.new("It crashed")
    exception.bugsnag_context = "exception_context"

    Bugsnag.notify(exception) do |report|
      report.context = "override_context"
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("override_context")
    }
  end

  it "accepts meta_data in overrides (for backwards compatibility) and merge it into metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({
        some_tab: {
          info: "here",
          data: "also here"
        }
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )
    }
  end

  it "truncates large meta_data before sending" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({
        some_tab: {
          giant: SecureRandom.hex(1_000_000/2),
          mega: SecureRandom.hex(1_000_000/2)
        }
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      # Truncated body should be no bigger than
      # 2 truncated hashes (4096*2) + rest of payload (20000)
      expect(::JSON.dump(payload).length).to be < 4096*2 + 20000
    }
  end

  it "truncates large messages before sending" do
    Bugsnag.notify(BugsnagTestException.new(SecureRandom.hex(250_000))) do |report|
      report.meta_data.merge!({
        some_tab: {
          giant: SecureRandom.hex(500_000/2),
          mega: SecureRandom.hex(500_000/2)
        }
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      expect(::JSON.dump(payload).length).to be < Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
    }
  end

  it "truncate large stacktraces before sending" do
    ex = BugsnagTestException.new("It crashed")
    stacktrace = []
    20000.times {|i| stacktrace.push("/Some/path/rspec/example.rb:113:in `instance_eval'")}
    ex.set_backtrace(stacktrace)
    Bugsnag.notify(ex)

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      # Truncated body should be no bigger than
      # 400 stacktrace lines * approx 60 chars per line + rest of payload (20000)
      expect(::JSON.dump(payload).length).to be < Bugsnag::Helpers::MAX_PAYLOAD_LENGTH
    }
  end

  it "accepts a severity in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.severity = "info"
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("info")
    }

  end

  it "defaults to warning severity" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["severity"]).to eq("warning")
    }
  end

  it "accepts a context in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.context = 'test_context'
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("test_context")
    }
  end

  it "accepts a user_id in overrides" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.user = {id: 'test_user'}
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["user"]["id"]).to eq("test_user")
    }
  end

  it "does not send an automatic notification if auto_notify is false" do
    Bugsnag.configure do |config|
      config.auto_notify = false
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"), true)

    expect(Bugsnag).not_to have_sent_notification
  end

  it "contains a release_stage" do
    Bugsnag.configure do |config|
      config.release_stage = "production"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].length).to eq(1)
    }
  end

  it "uses the https://notify.bugsnag.com endpoint by default" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(WebMock).to have_requested(:post, "https://notify.bugsnag.com")
  end

  it "does not mark the top-most stacktrace line as inProject if out of project" do
    Bugsnag.configuration.project_root = "/Random/location/here"

    begin
      "Test".prepnd "T"
    rescue Exception => e
      Bugsnag.notify(e)
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].size).to be >= 1
      expect(exception["stacktrace"].first["inProject"]).to be_nil
    }
  end

  it "marks the top-most stacktrace line as inProject if necessary" do
    Bugsnag.configuration.project_root = File.expand_path File.dirname(__FILE__)

    begin
      "Test".prepnd "T"
    rescue Exception => e
      Bugsnag.notify(e)
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["stacktrace"].size).to be >= 1
      expect(exception["stacktrace"][0]["inProject"]).to eq(true)
    }
  end

  it 'marks vendored stack frames as out-of-project' do
    project_root = File.expand_path File.dirname(__FILE__)
    Bugsnag.configuration.project_root = project_root

    ex = Exception.new('Division by zero')
    allow(ex).to receive (:backtrace) {[
      File.join(project_root, "vendor/strutils/lib/string.rb:508:in `splice'"),
      File.join(project_root, "vendors/strutils/lib/string.rb:508:in `splice'"),
      File.join(project_root, "lib/helpers/string.rb:32:in `splice'"),
      File.join(project_root, "lib/vendor/lib/article.rb:158:in `initialize'"),
      File.join(project_root, "lib/prog.rb:158:in `read_articles'"),
      File.join(project_root, ".bundle/strutils/lib.string.rb:508:in `splice'"),
      File.join(project_root, "abundle/article.rb:158:in `initialize'"),
      File.join(project_root, ".bundles/strutils/lib.string.rb:508:in `splice'"),
      File.join(project_root, "lib/.bundle/article.rb:158:in `initialize'"),
      "app.rb:10:in `main'",
      "(pry):3:in `__pry__'"
    ]}
    Bugsnag.notify(ex)
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)

      expect(exception["stacktrace"][0]["inProject"]).to be_nil
      expect(exception["stacktrace"][1]["inProject"]).to be true
      expect(exception["stacktrace"][2]["inProject"]).to be true
      expect(exception["stacktrace"][3]["inProject"]).to be true
      expect(exception["stacktrace"][4]["inProject"]).to be true
      expect(exception["stacktrace"][5]["inProject"]).to be_nil
      expect(exception["stacktrace"][6]["inProject"]).to be true
      expect(exception["stacktrace"][7]["inProject"]).to be true
      expect(exception["stacktrace"][8]["inProject"]).to be true
      expect(exception["stacktrace"][9]["inProject"]).to be_nil
      expect(exception["stacktrace"][10]["inProject"]).to be_nil
    }
  end

  it "adds app_version to the payload if it is set" do
    Bugsnag.configuration.app_version = "1.1.1"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["app"]["version"]).to eq("1.1.1")
    }
  end

  it "filters params from all payload hashes if they are set in default meta_data_filters" do

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({
        :request => {
          :params => {
            :password => "1234",
            :other_password => "12345",
            :other_data => "123456"
          },
          :cookie => "1234567890",
          :authorization => "token",
          :user_authorization => "token",
          :secret_key => "key",
          :user_secret => "key"
        }
      })
      report.meta_data.merge!({
        :session => {
          :"warden.user.user.key" => "1234",
          :"warden.user.foobar.key" => "1234",
          :"warden.user.test" => "1234"
        }
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("123456")
      expect(event["metaData"]["request"]["cookie"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["authorization"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["user_authorization"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["secret_key"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["user_secret"]).to eq("[FILTERED]")
      expect(event["metaData"]["session"]).not_to be_nil
      expect(event["metaData"]["session"]["warden.user.user.key"]).to eq("[FILTERED]")
      expect(event["metaData"]["session"]["warden.user.foobar.key"]).to eq("[FILTERED]")
      expect(event["metaData"]["session"]["warden.user.test"]).to eq("1234")
    }
  end

  it "filters params from all payload hashes if they are added to meta_data_filters" do

    Bugsnag.configuration.meta_data_filters << "other_data"
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
    }
  end

  it "filters params from all payload hashes if they are added to meta_data_filters as regex" do

    Bugsnag.configuration.meta_data_filters << /other_data/
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]["password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_password"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
    }
  end

  it "filters params from all payload hashes if they are added to meta_data_filters as partial regex" do

    Bugsnag.configuration.meta_data_filters << /r_data/
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({:request => {:params => {:nil_param => nil}}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["request"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).not_to be_nil
      expect(event["metaData"]["request"]["params"]).to have_key("nil_param")
    }
  end

  it "does not notify if report ignored" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.ignore!
    end

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if the exception class is in the default ignore_classes list" do
    Bugsnag.configuration.ignore_classes << ActiveRecord::RecordNotFound
    Bugsnag.notify(ActiveRecord::RecordNotFound.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if the non-default exception class is added to the ignore_classes" do
    Bugsnag.configuration.ignore_classes << BugsnagTestException

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if exception's ancestor is an ignored class" do
    Bugsnag.configuration.ignore_classes << BugsnagTestException

    Bugsnag.notify(BugsnagSubclassTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "does not notify if any caused exception is an ignored class" do
    Bugsnag.configuration.ignore_classes << NestedException

    ex = NestedException.new("Self-referential exception")
    ex.original_exception = BugsnagTestException.new("It crashed")

    Bugsnag.notify(ex)

    expect(Bugsnag).not_to have_sent_notification
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(2)
    }
  end

  it "does not unwrap the same exception twice" do
    ex = NestedException.new("Self-referential exception")
    ex.original_exception = ex

    Bugsnag.notify(ex)

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(1)
    }
  end

  it "does not unwrap more than 5 exceptions" do

    first_ex = ex = NestedException.new("Deep exception")
    10.times do |idx|
      ex = ex.original_exception = NestedException.new("Deep exception #{idx}")
    end

    Bugsnag.notify(first_ex)
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].size).to eq(5)
    }
  end

  it "calls to_exception on i18n error objects" do
    Bugsnag.notify(OpenStruct.new(:to_exception => BugsnagTestException.new("message")))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception["errorClass"]).to eq("BugsnagTestException")
      expect(exception["message"]).to eq("message")
    }
  end

  it "generates runtimeerror for non exceptions" do
    notify_test_exception

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
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

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({fluff: {fluff: invalid_data}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      if defined?(Encoding::UTF_8)
        expect(event['metaData']['fluff']['fluff']).to match(/fl�ff/)
      else
        expect(event['metaData']['fluff']['fluff']).to match(/flff/)
      end
    }
  end

  if RUBY_VERSION < '2.3.0'
    it "should handle utf8 encoding errors in exceptions_list" do
      invalid_data = "\"foo\xEBbar\""
      invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

      begin
        JSON.parse(invalid_data)
      rescue
        Bugsnag.notify $!
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        if defined?(Encoding::UTF_8)
          expect(payload.to_json).to match(/foo�bar/)
        else
          expect(payload.to_json).to match(/foobar/)
        end
      }
    end
  end

  it "should handle utf8 encoding errors in notification context" do
    invalid_data = "\"foo\xEBbar\""
    invalid_data = invalid_data.force_encoding("utf-8") if invalid_data.respond_to?(:force_encoding)

    begin
      raise
    rescue
      Bugsnag.notify($!) do |report|
        report.context = invalid_data
      end
    end

    expect(Bugsnag).to have_sent_notification { |payload, headers|
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

    expect(Bugsnag).to have_sent_notification { |payload, headers|
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

    expect(Bugsnag).to have_sent_notification { |payload, headers|
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

    expect(Bugsnag).to have_sent_notification { |payload, headers|
      if defined?(Encoding::UTF_8)
        expect(payload.to_json).to match(/foo�bar/)
      else
        expect(payload.to_json).to match(/foobar/)
      end
    }
  end

  it 'should handle exceptions with empty backtrace' do
    begin
      err = RuntimeError.new
      err.set_backtrace([])
      raise err
    rescue
      Bugsnag.notify $!
    end

    expect(Bugsnag).to have_sent_notification { |payload, headers|
      exception = get_exception_from_payload(payload)
      expect(exception['stacktrace'].size).to be > 0
    }
  end

  it 'should use defaults when notify is called' do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      expect(event["unhandled"]).to be false
      expect(event["severityReason"]).to eq({"type" => "handledException"})
    }
  end

  it 'should attach severity reason through a block when auto_notify is true' do
    Bugsnag.notify(BugsnagTestException.new("It crashed"), true) do |report|
      report.severity_reason = {
        :type => "middleware_handler",
        :attributes => {
          :name => "middleware_test"
        }
      }
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      expect(event["severityReason"]).to eq(
        {
          "type" => "middleware_handler",
          "attributes" => {
            "name" => "middleware_test"
          }
        }
      )
      expect(event["unhandled"]).to be true
    }
  end

  it 'should not attach severity reason from callback when auto_notify is false' do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.severity_reason = {
        :type => "middleware_handler",
        :attributes => {
          :name => "middleware_test"
        }
      }
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      expect(event["unhandled"]).to be false
      expect(event["severityReason"]).to eq({"type" => "handledException"})
    }
  end

  it 'does not notify if skip_bugsnag is true' do
    exception = BugsnagTestException.new("It crashed")
    exception.skip_bugsnag = true
    Bugsnag.notify(exception)
    expect(Bugsnag).not_to have_sent_notification
  end

  it 'uses an appropriate message if nil is notified' do
    Bugsnag.notify(nil)
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      exception = event["exceptions"][0]
      expect(exception["errorClass"]).to eq("RuntimeError")
      expect(exception["message"]).to eq("'nil' was notified as an exception")
    }
  end

  it "includes bugsnag lines marked out of project" do
    notify_test_exception
    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      exception = get_exception_from_payload(payload)
      bugsnag_count = 0
      exception["stacktrace"].each do |frame|
        if /.*lib\/bugsnag.*\.rb/.match(frame["file"])
          bugsnag_count += 1
          expect(frame["inProject"]).to be_nil
        end
      end
      # 7 is used here as the called bugsnag frames for a `notify` call should be:
      # - Bugsnag.notify
      # - Report.new
      # - Report.initialize
      # - Report.generate_exceptions_list
      # - Report.generate_exceptions_list | raw_exceptions.map
      # - Report.generate_exceptions_list | raw_exceptions.map | block
      # - Report.generate_exceptions_list | raw_exceptions.map | block | Stacktrace.new
      # However, JRUBY does not include the two `new` frames, resulting in 5 bugsnag frames
      if defined?(JRUBY_VERSION)
        frame_count = 5
      else
        frame_count = 7
      end
      expect(bugsnag_count).to equal frame_count
    }
  end

  describe "breadcrumbs" do
    let(:timestamp_regex) { /^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:[\d\.]+Z$/ }

    it "includes left breadcrumbs" do
      Bugsnag.leave_breadcrumb("Test breadcrumb")
      notify_test_exception
      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["breadcrumbs"].size).to eq(1)
        expect(event["breadcrumbs"].first).to match({
          "name" => "Test breadcrumb",
          "type" => "manual",
          "metaData" => {},
          "timestamp" => match(timestamp_regex)
        })
      }
    end

    it "filters left breadcrumbs" do
      Bugsnag.leave_breadcrumb("Test breadcrumb", {
        :forbidden_key => false,
        :allowed_key => true
      })
      Bugsnag.configuration.meta_data_filters << "forbidden"
      notify_test_exception
      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["breadcrumbs"].size).to eq(1)
        expect(event["breadcrumbs"].first).to match({
          "name" => "Test breadcrumb",
          "type" => "manual",
          "metaData" => {
            "forbidden_key" => "[FILTERED]",
            "allowed_key" => true
          },
          "timestamp" => match(timestamp_regex)
        })
      }
    end

    it "defaults to an empty array" do
      notify_test_exception
      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["breadcrumbs"].size).to eq(0)
      }
    end

    it "allows breadcrumbs to be editted in callbacks" do
      Bugsnag.leave_breadcrumb("Test breadcrumb")
      Bugsnag.before_notify_callbacks << Proc.new { |report|
        breadcrumb = report.breadcrumbs.first
        breadcrumb.meta_data = {:a => 1, :b => 2}
      }
      notify_test_exception
      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["breadcrumbs"].size).to eq(1)
        expect(event["breadcrumbs"].first).to match({
          "name" => "Test breadcrumb",
          "type" => "manual",
          "metaData" => {"a" => 1, "b" => 2},
          "timestamp" => match(timestamp_regex)
        })
      }
    end
  end

  describe "#summary" do
    it "provides a hash of the name, message, and severity" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report = Bugsnag::Report.new(e, Bugsnag.configuration)

        expect(report.summary).to eq({
          :error_class => "ZeroDivisionError",
          :message => "divided by 0",
          :severity => "warning"
        })
      end
    end

    it "handles strings" do
      report = Bugsnag::Report.new("test string", Bugsnag.configuration)

      expect(report.summary).to eq({
        :error_class => "RuntimeError",
        :message => "test string",
        :severity => "warning"
      })
    end

    it "handles error edge cases" do
      report = Bugsnag::Report.new(Timeout::Error, Bugsnag.configuration)

      expect(report.summary).to eq({
        :error_class => "Timeout::Error",
        :message => "Timeout::Error",
        :severity => "warning"
      })
    end

    it "handles empty exceptions" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report = Bugsnag::Report.new(e, Bugsnag.configuration)

        report.exceptions = []

        expect(report.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end

    it "handles removed exceptions" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report = Bugsnag::Report.new(e, Bugsnag.configuration)

        report.exceptions = nil

        expect(report.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end

    it "handles exceptions being replaced" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report = Bugsnag::Report.new(e, Bugsnag.configuration)

        report.exceptions = "no one should ever do this"

        expect(report.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end
  end

  if defined?(JRUBY_VERSION)

    it "should work with java.lang.Throwables" do
      begin
        JRubyException.raise!
      rescue
        Bugsnag.notify $!
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["errorClass"]).to eq('Java::JavaLang::NullPointerException')
        expect(exception["message"]).to eq("")
        expect(exception["stacktrace"].size).to be > 0
      }
    end
  end

  it 'should include device data when notify is called' do
    Bugsnag.configuration.hostname = 'test-host'
    Bugsnag.configuration.runtime_versions["ruby"] = '9.9.9'
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = payload["events"][0]
      expect(event["device"]["hostname"]).to eq('test-host')
      expect(event["device"]["runtimeVersions"]["ruby"]).to eq('9.9.9')
    }
  end
end
