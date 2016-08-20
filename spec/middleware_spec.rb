require 'spec_helper'
require 'fixtures/middleware/public_info_setter'
require 'fixtures/middleware/internal_info_setter'

describe Bugsnag::MiddlewareStack do
  it "runs before_bugsnag_notify callbacks, adding a tab" do
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:some_tab, {
        :info => "here",
        :data => "also here"
      })
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(1)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["some_tab"]).not_to be_nil
      expect(event["metaData"]["some_tab"]["info"]).to eq("here")
      expect(event["metaData"]["some_tab"]["data"]).to eq("also here")
    }

  end

  it "runs before_bugsnag_notify callbacks, adding custom data" do
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:custom, {info: "here"})
      notif.add_tab(:custom, {data: "also here"})

      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(1)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).not_to be_nil
      expect(event["metaData"]["custom"]["info"]).to eq("here")
      expect(event["metaData"]["custom"]["data"]).to eq("also here")
    }

  end

  it "runs before_bugsnag_notify callbacks, setting the user" do
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.user = {:id => "here", :email => "also here", :name => "also here too", :random_key => "also here too too"}
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(1)

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["user"]).not_to be_nil
      expect(event["user"]["id"]).to eq("here")
      expect(event["user"]["email"]).to eq("also here")
      expect(event["user"]["name"]).to eq("also here too")
      expect(event["user"]["random_key"]).to eq("also here too too")
    }

  end

  it "allows block to override values set by internal middleware" do
    Bugsnag.configuration.internal_middleware.use(InternalInfoSetter)
    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({custom: {info: 'overridden'}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).not_to be_nil
      expect(event["metaData"]["custom"]["info"]).to eq("overridden")
    }
  end

  it "allows block to override public middleware" do
    Bugsnag.configuration.middleware.use(PublicInfoSetter)

    Bugsnag.notify(BugsnagTestException.new("It crashed")) do |report|
      report.meta_data.merge!({custom: {info: 'overridden'}})
    end

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).not_to be_nil
      expect(event["metaData"]["custom"]["info"]).to eq("overridden")
    }
  end

  it "does not have have before callbacks by default" do
    expect(Bugsnag.before_notify_callbacks.size).to eq(0)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"].size).to eq(0)
    }
  end

  it "does not execute disabled bugsnag middleware" do
    callback_run_count = 0
    Bugsnag.configure do |config|
      config.middleware.disable(Bugsnag::Middleware::Callbacks)
    end

    Bugsnag.before_notify_callbacks << lambda {|notif|
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(0)
  end

  it "does not notify if a callback told so" do
    Bugsnag.before_notify_callbacks << lambda do |notif|
      notif.ignore!
    end
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(Bugsnag).not_to have_sent_notification
  end

  it "allows inspection of meta_data before ignoring exception" do
    # Use before notify callbacks as only the callback based metadata is
    # available to before_notify_callbacks
    Bugsnag.before_notify_callbacks << lambda do |notif|
      notif.add_tab(:sidekiq, {:retry_count => 4})
    end

    Bugsnag.before_notify_callbacks << lambda do |notif|
      notif.ignore! if notif.meta_data[:sidekiq][:retry_count] > 3
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(Bugsnag).not_to have_sent_notification

  end

  it "allows meta_data to be modified in a middleware" do
    MetaDataAdder = Class.new do
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end

      def call(report)
        report.meta_data = {test: {value: "abcdef123456abcdef123456abcdef123456"}}
        @bugsnag.call(report)
      end
    end

    MetaDataMunger = Class.new do
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end

      def call(report)
        token = report.meta_data[:test][:value]
        report.meta_data[:test][:value] = "#{token[0...6]}*****#{token[-4..-1]}"
        @bugsnag.call(report)
      end
    end

    Bugsnag.configure do |c|
      c.middleware.use MetaDataAdder
      c.middleware.use MetaDataMunger
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]['test']['value']).to eq("abcdef*****3456")
    }
  end

end
