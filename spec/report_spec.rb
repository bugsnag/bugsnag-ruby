# encoding: utf-8
require_relative './spec_helper'
require 'securerandom'
require 'ostruct'
require 'support/shared_examples_for_metadata'

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

if RUBY_VERSION >= '2.0.0'
  require_relative './support/exception_with_detailed_message'
else
  require_relative './support/exception_with_detailed_message_ruby_1'
end

class ExceptionWithDetailedMessageButNoHighlight < Exception
  def detailed_message
    "detail about '#{self}'"
  end
end

class ExceptionWithDetailedMessageReturningEncodedString < Exception
  def initialize(message, encoding)
    super(message)
    @encoding = encoding
  end

  def detailed_message
    "abc #{self} xyz".encode(@encoding)
  end
end

shared_examples "Report or Event tests" do |class_to_test|
  context "metadata" do
    include_examples(
      "metadata delegate",
      lambda do |metadata, *args|
        report = class_to_test.new(RuntimeError.new, Bugsnag.configuration)
        report.metadata = metadata

        report.add_metadata(*args)
      end,
      lambda do |metadata, *args|
        report = class_to_test.new(RuntimeError.new, Bugsnag.configuration)
        report.metadata = metadata

        report.clear_metadata(*args)
      end
    )
  end

  it "#headers should return the correct request headers" do
    fake_now = Time.gm(2020, 1, 2, 3, 4, 5, 123456)
    expect(Time).to receive(:now).at_least(:twice).and_return(fake_now)

    report_or_event = class_to_test.new(
      BugsnagTestException.new("It crashed"),
      Bugsnag.configuration
    )

    expect(report_or_event.headers).to eq({
      "Bugsnag-Api-Key" => "c9d60ae4c7e70c4b6c4ebd3e8056d2b8",
      "Bugsnag-Payload-Version" => "4.0",
      # This matches the time we stubbed earlier (fake_now)
      "Bugsnag-Sent-At" => "2020-01-02T03:04:05.123Z"
    })
  end

  describe "#summary" do
    it "provides a hash of the name, message, and severity" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report_or_event = class_to_test.new(e, Bugsnag.configuration)

        expect(report_or_event.summary).to eq({
          :error_class => "ZeroDivisionError",
          :message => "divided by 0",
          :severity => "warning"
        })
      end
    end

    it "handles strings" do
      report_or_event = class_to_test.new("test string", Bugsnag.configuration)

      expect(report_or_event.summary).to eq({
        :error_class => "RuntimeError",
        :message => "test string",
        :severity => "warning"
      })
    end

    it "handles error edge cases" do
      report_or_event = class_to_test.new(Timeout::Error, Bugsnag.configuration)

      expect(report_or_event.summary).to eq({
        :error_class => "Timeout::Error",
        :message => "Timeout::Error",
        :severity => "warning"
      })
    end

    it "uses Exception#detailed_message if available" do
      exception = ExceptionWithDetailedMessage.new("some message")
      report_or_event = class_to_test.new(exception, Bugsnag.configuration)

      expect(report_or_event.summary).to eq({
        error_class: "ExceptionWithDetailedMessage",
        message: "some message with some extra detail",
        severity: "warning"
      })
    end

    it "handles empty exceptions" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report_or_event = class_to_test.new(e, Bugsnag.configuration)

        report_or_event.exceptions = []

        expect(report_or_event.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end

    it "handles removed exceptions" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report_or_event = class_to_test.new(e, Bugsnag.configuration)

        report_or_event.exceptions = nil

        expect(report_or_event.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end

    it "handles exceptions being replaced" do
      begin
        1/0
      rescue ZeroDivisionError => e
        report_or_event = class_to_test.new(e, Bugsnag.configuration)

        report_or_event.exceptions = "no one should ever do this"

        expect(report_or_event.summary).to eq({
          :error_class => "Unknown",
          :severity => "warning"
        })
      end
    end
  end

  describe "#errors" do
    it "has required attributes" do
      exception = RuntimeError.new("example error")
      report = class_to_test.new(exception, Bugsnag.configuration)

      expect(report.errors.length).to eq(1)

      error = report.errors.first

      expect(error).to respond_to(:error_class)
      expect(error).to respond_to(:error_message)
      expect(error).to respond_to(:type)
      expect(error).to respond_to(:stacktrace)

      expect(error).to respond_to(:error_class=)
      expect(error).to respond_to(:error_message=)
      expect(error).to respond_to(:type=)
      expect(error).not_to respond_to(:stacktrace=)
    end

    it "includes errors that caused the top-most exception" do
      begin
        begin
          raise "one"
        rescue
          Ruby21Exception.raise!("two")
        end
      rescue => exception
      end

      report = class_to_test.new(exception, Bugsnag.configuration)

      expect(report.errors.length).to eq(2)

      expect(report.errors[0].stacktrace).not_to be_empty
      expect(report.errors[0]).to have_attributes({
        error_class: "Ruby21Exception",
        error_message: "two",
        type: "ruby"
      })

      expect(report.errors[1].stacktrace).not_to be_empty
      expect(report.errors[1]).to have_attributes({
        error_class: "RuntimeError",
        error_message: "one",
        type: "ruby"
      })
    end

    it "cannot be assigned to" do
      exception = RuntimeError.new("example error")
      report = class_to_test.new(exception, Bugsnag.configuration)

      expect(report).not_to respond_to(:errors=)
    end

    it "can be mutated" do
      exception = RuntimeError.new("example error")
      report = class_to_test.new(exception, Bugsnag.configuration)

      report.errors.push("haha")
      report.errors.push("haha 2")
      report.errors.pop

      expect(report.errors.length).to eq(2)

      expect(report.errors.first.stacktrace).not_to be_empty
      expect(report.errors.first).to have_attributes({
        error_class: "RuntimeError",
        error_message: "example error",
        type: "ruby"
      })

      expect(report.errors[1]).to eq("haha")
    end

    it "contains mutable data" do
      exception = RuntimeError.new("example error")
      report = class_to_test.new(exception, Bugsnag.configuration)

      expect(report.errors.length).to eq(1)

      report.errors.first.error_class = "haha"
      report.errors.first.error_message = "ahah"
      report.errors.first.type = "aahh"

      expect(report.errors.first.stacktrace).not_to be_empty
      expect(report.errors.first).to have_attributes({
        error_class: "haha",
        error_message: "ahah",
        type: "aahh"
      })
    end

    it "shares the stacktrace with #exceptions" do
      exception = RuntimeError.new("example error")
      report = class_to_test.new(exception, Bugsnag.configuration)

      expect(report.errors.length).to eq(1)
      expect(report.exceptions.length).to eq(1)

      error = report.errors.first
      exception = report.exceptions.first

      expect(error.stacktrace).not_to be_empty
      expect(error.stacktrace).to all(have_key(:lineNumber))
      expect(error.stacktrace).to all(have_key(:file))
      expect(error.stacktrace).to all(have_key(:method))
      expect(error.stacktrace).to all(have_key(:code))

      expect(error.stacktrace).to be(exception[:stacktrace])
    end

    it "mutating the stacktrace affects the payload" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        expect(report.errors.length).to eq(1)

        error = report.errors.first

        error.stacktrace.clear
        error.stacktrace[0] = {
          lineNumber: 123,
          file: "/dev/null",
          method: "do_nothing",
          code: "yes, lots"
        }
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        exception = get_exception_from_payload(payload)

        expect(exception["stacktrace"]).to eq(
          [
            {
              "lineNumber" => 123,
              "file" => "/dev/null",
              "method" => "do_nothing",
              "code" => "yes, lots"
            }
          ]
        )
      })
    end

    it "uses Exception#detailed_message if available" do
      exception = ExceptionWithDetailedMessage.new("some message")
      report_or_event = class_to_test.new(exception, Bugsnag.configuration)

      expect(report_or_event.errors.length).to eq(1)

      message = report_or_event.errors.first.error_message

      expect(message).to eq("some message with some extra detail")
    end
  end

  it "has a reference to the original error" do
    exception = RuntimeError.new("example error")
    report = class_to_test.new(exception, Bugsnag.configuration)

    expect(report.original_error).to be(exception)
  end
end

# rubocop:disable Metrics/BlockLength
describe Bugsnag::Report do
  include_examples("Report or Event tests", Bugsnag::Report)
  include_examples("Report or Event tests", Bugsnag::Event)

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
      # The default ignore classes includes SignalException, so we need to
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

  it "metadata added with 'add_metadata' ends up in the payload" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_metadata(
        :some_tab,
        { info: "here", data: "also here" }
      )

      report.add_metadata(:some_other_tab, :info, true)
      report.add_metadata(:some_other_tab, :data, "very true")
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).to eq({
        "some_tab" => {
          "info" => "here",
          "data" => "also here"
        },
        "some_other_tab" => {
          "info" => true,
          "data" => "very true"
        }
      })
    })
  end

  it "metadata removed with 'clear_metadata' does not end up in the payload" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_metadata(
        :some_tab,
        { info: "here", data: "also here" }
      )

      report.add_metadata(:some_other_tab, :info, true)
      report.add_metadata(:some_other_tab, :data, "very true")

      report.clear_metadata(:some_tab)
      report.clear_metadata(:some_other_tab, :info)
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]).to eq({
        "some_other_tab" => { "data" => "very true" }
      })
    })
  end

  it "accepts tabs in overrides and adds them to metaData" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({
        some_tab: {
          info: "here",
          data: "also here"
        }
      })

      report.metadata.merge!({
        some_other_tab: {
          info: true,
          data: "very true"
        }
      })
    end

    expect(Bugsnag).to(have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq(
        "info" => "here",
        "data" => "also here"
      )

      expect(event["metaData"]["some_other_tab"]).to eq(
        "info" => true,
        "data" => "very true"
      )
    })
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

  it "uses automatic context if no other context has been set" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.automatic_context = "automatic context"
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("automatic context")
    })
  end

  it "uses Configuration context even if the automatic context has been set" do
    Bugsnag.configure do |config|
      config.context = "configuration context"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.automatic_context = "automatic context"
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("configuration context")
    })
  end

  it "uses overridden context even if the automatic context has been set" do
    Bugsnag.configure do |config|
      config.context = "configuration context"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.context = "overridden context"
      report.automatic_context = "automatic context"
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("overridden context")
    })
  end

  it "uses overridden context even it is set to 'nil'" do
    Bugsnag.configure do |config|
      config.context = nil
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.automatic_context = "automatic context"
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to be_nil
    })
  end

  it "uses the context from Configuration, if set" do
    Bugsnag.configure do |config|
      config.context = "example context"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("example context")
    })
  end

  it "allows overriding the context from Configuration" do
    Bugsnag.configure do |config|
      config.context = "example context"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.context = "different context"
    end

    expect(Bugsnag).to(have_sent_notification { |payload, _headers|
      event = get_event_from_payload(payload)
      expect(event["context"]).to eq("different context")
    })
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

  it "respects the enabled_release_stages setting by not sending in development" do
    Bugsnag.configuration.enabled_release_stages = ["production"]
    Bugsnag.configuration.release_stage = "development"

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).not_to have_sent_notification
  end

  it "respects the enabled_release_stages setting when set" do
    Bugsnag.configuration.release_stage = "development"
    Bugsnag.configuration.enabled_release_stages = ["development"]
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to(have_sent_notification { |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["exceptions"].length).to eq(1)
    })
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

      report.metadata.merge!({
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
      report.metadata.merge!({:request => {:params => {:password => "1234", :other_password => "123456", :other_data => "123456"}}})
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

  it "does not apply filters outside of report.meta_data" do
    Bugsnag.configuration.meta_data_filters << "data"

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data = {
        xyz: "abc",
        data: "123456"
      }

      report.user = {
        id: 123,
        data: "hello"
      }
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)

      expect(event["metaData"]).not_to be_nil
      expect(event["metaData"]["xyz"]).to eq("abc")
      expect(event["metaData"]["data"]).to eq("[FILTERED]")

      expect(event["user"]).not_to be_nil
      expect(event["user"]["data"]).to eq("hello")
    }
  end

  it "filters params from all payload hashes if they are added to redacted_keys as a string" do
    Bugsnag.configuration.redacted_keys << "other_data"

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_metadata(:request, {
        params: {
          password: "1234",
          other_password: "123456",
          other_data: "123456",
          more_other_data: "123456",
          abc: "xyz"
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
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["more_other_data"]).to eq("123456")
      expect(event["metaData"]["request"]["params"]["abc"]).to eq("xyz")
    }
  end

  it "filters params from all payload hashes if they are added to redacted_keys as partial regex" do
    Bugsnag.configuration.redacted_keys << /r_data/

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_metadata(:request, {
        params: {
          password: "1234",
          other_password: "123456",
          other_data: "123456",
          more_other_data: "123456",
          abc: "xyz"
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
      expect(event["metaData"]["request"]["params"]["other_data"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["more_other_data"]).to eq("[FILTERED]")
      expect(event["metaData"]["request"]["params"]["abc"]).to eq("xyz")
    }
  end

  it "does not notify if report ignored" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.ignore!
    end

    expect(Bugsnag).not_to have_sent_notification
  end

  context "ignore_classes" do
    context "as a constant" do
      it "ignores exception when its class is ignored" do
        Bugsnag.configuration.ignore_classes << BugsnagTestException

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).not_to have_sent_notification
      end

      it "ignores exception when its ancestor is ignored" do
        Bugsnag.configuration.ignore_classes << BugsnagTestException

        Bugsnag.notify(BugsnagSubclassTestException.new("It crashed"))

        expect(Bugsnag).not_to have_sent_notification
      end

      it "ignores exception when the original exception is ignored" do
        Bugsnag.configuration.ignore_classes << BugsnagTestException

        ex = NestedException.new("Self-referential exception")
        ex.original_exception = BugsnagTestException.new("It crashed")

        Bugsnag.notify(ex)

        expect(Bugsnag).not_to have_sent_notification
      end
    end

    context "as a proc" do
      it "ignores exception when the proc returns true" do
        Bugsnag.configuration.ignore_classes << ->(exception) { true }

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).not_to have_sent_notification
      end

      it "does not ignore exception when proc returns false" do
        Bugsnag.configuration.ignore_classes << ->(exception) { false }

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).to have_sent_notification { |payload, headers|
          exception = get_exception_from_payload(payload)

          expect(exception["errorClass"]).to eq("BugsnagTestException")
          expect(exception["message"]).to eq("It crashed")
        }
      end
    end
  end

  context "discard_classes" do
    context "as a string" do
      it "discards exception when its class should be discarded" do
        Bugsnag.configuration.discard_classes << "BugsnagTestException"

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).not_to have_sent_notification
      end

      it "discards exception when the original exception should be discarded" do
        Bugsnag.configuration.discard_classes << "BugsnagTestException"

        ex = NestedException.new("Self-referential exception")
        ex.original_exception = BugsnagTestException.new("It crashed")

        Bugsnag.notify(ex)

        expect(Bugsnag).not_to have_sent_notification
      end

      it "does not discard exception with a typo" do
        Bugsnag.configuration.discard_classes << "BugsnagToastException"

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).to have_sent_notification { |payload, headers|
          exception = get_exception_from_payload(payload)

          expect(exception["errorClass"]).to eq("BugsnagTestException")
          expect(exception["message"]).to eq("It crashed")
        }
      end

      it "does not discard exception when its ancestor is discarded" do
        Bugsnag.configuration.discard_classes << "BugsnagTestException"

        Bugsnag.notify(BugsnagSubclassTestException.new("It crashed"))

        expect(Bugsnag).to have_sent_notification { |payload, headers|
          exception = get_exception_from_payload(payload)

          expect(exception["errorClass"]).to eq("BugsnagSubclassTestException")
          expect(exception["message"]).to eq("It crashed")
        }
      end
    end

    context "as a regexp" do
      it "discards exception when its class should be discarded" do
        Bugsnag.configuration.discard_classes << /^BugsnagTest.*/

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).not_to have_sent_notification
      end

      it "discards exception when the original exception should be discarded" do
        Bugsnag.configuration.discard_classes << /^BugsnagTest.*/

        ex = NestedException.new("Self-referential exception")
        ex.original_exception = BugsnagTestException.new("It crashed")

        Bugsnag.notify(ex)

        expect(Bugsnag).not_to have_sent_notification
      end

      it "does not discard exception when regexp does not match" do
        Bugsnag.configuration.discard_classes << /^NotBugsnag.*/

        Bugsnag.notify(BugsnagTestException.new("It crashed"))

        expect(Bugsnag).to have_sent_notification { |payload, headers|
          exception = get_exception_from_payload(payload)

          expect(exception["errorClass"]).to eq("BugsnagTestException")
          expect(exception["message"]).to eq("It crashed")
        }
      end

      it "does not discard exception when its ancestor is discarded" do
        Bugsnag.configuration.discard_classes << /^BugsnagTest.*/

        Bugsnag.notify(BugsnagSubclassTestException.new("It crashed"))

        expect(Bugsnag).to have_sent_notification { |payload, headers|
          exception = get_exception_from_payload(payload)

          expect(exception["errorClass"]).to eq("BugsnagSubclassTestException")
          expect(exception["message"]).to eq("It crashed")
        }
      end
    end
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

  context "#detailed_message" do
    it "uses Exception#detailed_message if available" do
      Bugsnag.notify(ExceptionWithDetailedMessage.new("some message"))

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["errorClass"]).to eq("ExceptionWithDetailedMessage")
        expect(exception["message"]).to eq("some message with some extra detail")
      }
    end

    it "handles implementations of Exception#detailed_message with no 'highlight' parameter" do
      Bugsnag.notify(ExceptionWithDetailedMessageButNoHighlight.new("some message"))

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["errorClass"]).to eq("ExceptionWithDetailedMessageButNoHighlight")
        expect(exception["message"]).to eq("detail about 'some message'")
      }
    end

    it "converts ASCII_8BIT encoding to UTF-8" do
      Bugsnag.notify(Exception.new("大好き\n大好き"))

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["message"]).to eq("大好き\n大好き")
      }
    end

    it "leaves UTF-8 strings as-is" do
      exception = ExceptionWithDetailedMessageButNoHighlight.new("Обичам те\n大好き")
      expect(exception.detailed_message.encoding).to be(Encoding::UTF_8)

      Bugsnag.notify(exception)

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["message"]).to eq("detail about 'Обичам те\n大好き'")
      }
    end

    it "handles UTF-16 strings" do
      exception = ExceptionWithDetailedMessageReturningEncodedString.new("Обичам те\n大好き", Encoding::UTF_16)
      expect(exception.detailed_message.encoding).to be(Encoding::UTF_16)

      Bugsnag.notify(exception)

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)

        # the exception message is converted to UTF-8 by the Cleaner
        expect(exception["message"]).to eq("abc Обичам те\n大好き xyz")
      }
    end

    it "handles Shift JIS strings" do
      exception = ExceptionWithDetailedMessageReturningEncodedString.new("大好き\n大好き", Encoding::Shift_JIS)
      expect(exception.detailed_message.encoding).to be(Encoding::Shift_JIS)

      Bugsnag.notify(exception)

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)

        # the exception message is converted to UTF-8 by the Cleaner
        expect(exception["message"]).to eq("abc 大好き\n大好き xyz")
      }
    end
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

  it "should handle recursive metadata" do
    a = [1, 2, 3]
    b = [2, a]
    a << b
    c = [1, 2, 3]

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_tab(:some_tab, {
        a: a,
        b: b,
        c: c
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq({
        "a" => [1, 2, 3, [2, "[RECURSION]"]],
        "b" => [2, "[RECURSION]"],
        "c" => [1, 2, 3]
      })
    }
  end

  it "does not detect two equal objects as recursion" do
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.add_tab(:some_tab, {
        data: [1, [1, 2], [1, 2], "a"]
      })
    end

    expect(Bugsnag).to have_sent_notification{ |payload, headers|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).to eq({
        "data" => [1, [1, 2], [1, 2], "a"]
      })
    }
  end

  context "an object that throws if `to_s` is called" do
    class StringRaiser
      def to_s
        raise 'Oh no you do not!'
      end
    end

    it "uses the string '[RAISED]' instead" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          data: [1, 2, StringRaiser.new]
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "data" => [1, 2, "[RAISED]"]
        })
      }
    end

    it "replaces hash key with '[RAISED]'" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          StringRaiser.new => 1
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "[RAISED]" => "[FILTERED]"
        })
      }
    end

    it "uses a single '[RAISED]'key when multiple keys raise" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          StringRaiser.new => 1,
          StringRaiser.new => 2
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "[RAISED]" => "[FILTERED]"
        })
      }
    end
  end

  context "an object that infinitely recurse if `to_s` is called" do
    is_jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

    class StringRecurser
      def to_s
        to_s
      end
    end

    it "uses the string '[RECURSION]' instead" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          data: [1, 2, StringRecurser.new]
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "data" => [1, 2, "[RECURSION]"]
        })
      }
    end

    it "replaces hash key with '[RECURSION]'" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          StringRecurser.new => 1
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "[RECURSION]" => "[FILTERED]"
        })
      }
    end

    it "uses a single '[RECURSION]'key when multiple keys recurse" do
      skip "JRuby doesn't allow recovery from SystemStackErrors" if is_jruby

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.add_tab(:some_tab, {
          StringRecurser.new => 1,
          StringRecurser.new => 2
        })
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["some_tab"]).to eq({
          "[RECURSION]" => "[FILTERED]"
        })
      }
    end
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

      # 6 is used here as the called bugsnag frames for a `notify` call should be:
      # - Bugsnag.notify
      # - Report.new
      # - Report.initialize
      # - Report.generate_exceptions_list
      # - Report.generate_exceptions_list | raw_exceptions.map
      # - Report.generate_exceptions_list | raw_exceptions.map | block
      expect(bugsnag_count).to eq(6)
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

    it "redacted keys apply to breadcrumb metadata" do
      Bugsnag.leave_breadcrumb("Test breadcrumb", {
        :forbidden_key => false,
        :allowed_key => true
      })

      Bugsnag.configuration.redacted_keys << "forbidden_key"

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

  if defined?(JRUBY_VERSION)

    it "works with java.lang.Throwables" do
      begin
        pp "I'm failing!"
        JRubyException.raise!
        pp "I've failed"
      rescue => e
        pp "I'm notifying! #{e.message}"
        Bugsnag.notify $!
        pp "I've notified!"
      end

      expect(Bugsnag).to have_sent_notification{ |payload, headers|
        exception = get_exception_from_payload(payload)
        expect(exception["errorClass"]).to eq('Java::JavaLang::NullPointerException')
        expect(exception["message"]).to eq("")
        expect(exception["stacktrace"].size).to be > 0
      }
    end
  end

  it 'includes device data when notify is called' do
    fake_device_time = Time.gm(2020, 1, 2, 3, 4, 5, 123456)
    fake_sent_at = Time.gm(2021, 1, 2, 3, 4, 5, 123456)
    expect(Time).to receive(:now).at_least(:twice).and_return(fake_device_time, fake_sent_at)

    Bugsnag.configuration.hostname = 'test-host'
    Bugsnag.configuration.runtime_versions["ruby"] = '9.9.9'
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to(have_sent_notification { |payload, headers|
      event = payload["events"][0]
      expect(event["device"]["hostname"]).to eq('test-host')
      expect(event["device"]["runtimeVersions"]["ruby"]).to eq('9.9.9')
      # This matches the time we stubbed earlier (fake_device_time)
      expect(event["device"]["time"]).to eq("2020-01-02T03:04:05.123Z")

      expect(headers["Bugsnag-Api-Key"]).to eq("c9d60ae4c7e70c4b6c4ebd3e8056d2b8")
      expect(headers["Bugsnag-Payload-Version"]).to eq("4.0")
      # This matches the time we stubbed earlier (fake_sent_at)
      expect(headers["Bugsnag-Sent-At"]).to eq("2021-01-02T03:04:05.123Z")
    })
  end

  context "#user" do
    it "accepts an arbitrary user hash" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.user = { id: "test_user", abc: "xyz" }
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]["id"]).to eq("test_user")
        expect(event["user"]["abc"]).to eq("xyz")
      })
    end

    it "set_user will set the three supported fields" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.set_user("123", "abc.xyz@example.com", "abc xyz")
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]["id"]).to eq("123")
        expect(event["user"]["email"]).to eq("abc.xyz@example.com")
        expect(event["user"]["name"]).to eq("abc xyz")
      })
    end

    it "set_user will not set fields that are 'nil'" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.set_user("123", nil, "abc xyz")
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]["id"]).to eq("123")
        expect(event["user"]).not_to have_key("email")
        expect(event["user"]["name"]).to eq("abc xyz")
      })
    end

    it "set_user will unset all fields if passed no parameters" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.user = { id: "nope", email: "nah@example.com", name: "yes", other: "stuff" }

        report.set_user
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]).to be_empty
      })
    end

    it "set_user can be passed only an ID" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.set_user("123")
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]["id"]).to eq("123")
        expect(event["user"]).not_to have_key("email")
        expect(event["user"]).not_to have_key("name")
      })
    end

    it "set_user can be passed only an ID and email" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
        report.set_user("123", "123@example.com")
      end

      expect(Bugsnag).to(have_sent_notification { |payload, _headers|
        event = get_event_from_payload(payload)
        expect(event["user"]["id"]).to eq("123")
        expect(event["user"]["email"]).to eq("123@example.com")
        expect(event["user"]).not_to have_key("name")
      })
    end
  end

  it "reports the payload version in the header and body" do
    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to(have_sent_notification { |payload, headers|
      expect(headers["Bugsnag-Payload-Version"]).to eq("4.0")
      expect(payload["payloadVersion"]).to eq("4.0")
    })
  end

  describe "feature flags" do
    it "includes no feature flags by default" do
      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([])
      }
    end

    it "includes the Bugsnag module's feature flags if present" do
      Bugsnag.add_feature_flag('abc')
      Bugsnag.add_feature_flag('xyz', '123')

      Bugsnag.notify(BugsnagTestException.new("It crashed"))

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([
          { "featureFlag" => "abc" },
          { "featureFlag" => "xyz", "variant" => "123" },
        ])
      }
    end

    it "does not mutate the Bugsnag module's feature flags if more flags are added" do
      Bugsnag.add_feature_flag('abc')
      Bugsnag.add_feature_flag('xyz', '123')

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        event.add_feature_flag('another one')
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([
          { "featureFlag" => "abc" },
          { "featureFlag" => "xyz", "variant" => "123" },
          { "featureFlag" => "another one" },
        ])

        expect(Bugsnag.feature_flag_delegate.as_json).to eq([
          { "featureFlag" => "abc" },
          { "featureFlag" => "xyz", "variant" => "123" },
        ])
      }
    end

    it "does not mutate the Bugsnag module's feature flags if flags are removed" do
      Bugsnag.add_feature_flag('abc')
      Bugsnag.add_feature_flag('xyz', '123')

      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        event.clear_feature_flags
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to be_empty

        expect(Bugsnag.feature_flag_delegate.as_json).to eq([
          { "featureFlag" => "abc" },
          { "featureFlag" => "xyz", "variant" => "123" },
        ])
      }
    end

    it "can add individual feature flags to the payload" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        event.add_feature_flag("flag 1")
        event.add_feature_flag("flag 2", "1234")
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([
          { "featureFlag" => "flag 1" },
          { "featureFlag" => "flag 2", "variant" => "1234" },
        ])
      }
    end

    it "can add multiple feature flags to the payload in one go" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        flags = [
          Bugsnag::FeatureFlag.new("a"),
          Bugsnag::FeatureFlag.new("b"),
          Bugsnag::FeatureFlag.new("c", "1"),
          Bugsnag::FeatureFlag.new("d", "2"),
        ]

        event.add_feature_flags(flags)
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([
          { "featureFlag" => "a" },
          { "featureFlag" => "b" },
          { "featureFlag" => "c", "variant" => "1" },
          { "featureFlag" => "d", "variant" => "2" },
        ])
      }
    end

    it "can remove a feature flag from the payload" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        flags = [
          Bugsnag::FeatureFlag.new("a"),
          Bugsnag::FeatureFlag.new("b"),
          Bugsnag::FeatureFlag.new("c", "1"),
          Bugsnag::FeatureFlag.new("d", "2"),
        ]

        event.add_feature_flags(flags)
        event.add_feature_flag("e")

        event.clear_feature_flag("b")
        event.clear_feature_flag("d")
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([
          { "featureFlag" => "a" },
          { "featureFlag" => "c", "variant" => "1" },
          { "featureFlag" => "e" },
        ])
      }
    end

    it "can remove all feature flags from the payload" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        flags = [
          Bugsnag::FeatureFlag.new("a"),
          Bugsnag::FeatureFlag.new("b"),
          Bugsnag::FeatureFlag.new("c", "1"),
          Bugsnag::FeatureFlag.new("d", "2"),
        ]

        event.add_feature_flags(flags)
        event.add_feature_flag("e")

        event.clear_feature_flags
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([])
      }
    end

    it "can get feature flags from the event" do
      Bugsnag.notify(BugsnagTestException.new("It crashed")) do |event|
        flags = [
          Bugsnag::FeatureFlag.new("a"),
          Bugsnag::FeatureFlag.new("b"),
          Bugsnag::FeatureFlag.new("c", "1"),
          Bugsnag::FeatureFlag.new("d", "2"),
        ]

        event.add_feature_flags(flags)
        event.add_feature_flag("e")

        expect(event.feature_flags).to eq([
          Bugsnag::FeatureFlag.new("a"),
          Bugsnag::FeatureFlag.new("b"),
          Bugsnag::FeatureFlag.new("c", "1"),
          Bugsnag::FeatureFlag.new("d", "2"),
          Bugsnag::FeatureFlag.new("e"),
        ])

        event.clear_feature_flags
      end

      expect(Bugsnag).to have_sent_notification { |payload, headers|
        event = get_event_from_payload(payload)
        expect(event["featureFlags"]).to eq([])
      }
    end
  end
end
# rubocop:enable Metrics/BlockLength
