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
      notif.add_custom_data(:info, "here")
      notif.add_custom_data(:data, "also here")

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

  it "allows overrides to override values set by internal middleware" do
    Bugsnag.configuration.internal_middleware.use(InternalInfoSetter)
    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:info => "overridden"})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).not_to be_nil
      expect(event["metaData"]["custom"]["info"]).not_to eq(InternalInfoSetter::MESSAGE)
      expect(event["metaData"]["custom"]["info"]).to eq("overridden")
    }
  end

  it "doesn't allow overrides to override public middleware" do
    Bugsnag.configuration.middleware.use(PublicInfoSetter)

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:info => "overridden"})

    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"]["custom"]).not_to be_nil
      expect(event["metaData"]["custom"]["info"]).not_to eq("overridden")
      expect(event["metaData"]["custom"]["info"]).to eq(PublicInfoSetter::MESSAGE)
    }
  end

  it "does not have have before or after callbacks by default" do
    expect(Bugsnag.before_notify_callbacks.size).to eq(0)
    expect(Bugsnag.after_notify_callbacks.size).to eq(0)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(Bugsnag).to have_sent_notification{ |payload|
      event = get_event_from_payload(payload)
      expect(event["metaData"].size).to eq(0)
    }
  end

  it "runs after_bugsnag_notify callbacks" do
    callback_run_count = 0
    Bugsnag.after_notify_callbacks << lambda {|notif|
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))

    expect(callback_run_count).to eq(1)
    expect(Bugsnag::Notification).to have_sent_notification { }
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
    expect(Bugsnag::Notification).not_to have_sent_notification { }
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
    expect(Bugsnag::Notification).not_to have_sent_notification

  end

  it "allows meta_data to be modified in a middleware" do
    MetaDataMunger = Class.new do
      def initialize(bugsnag)
        @bugsnag = bugsnag
      end

      def call(notification)
        token = notification.meta_data[:sidekiq][:args].first
        notification.meta_data[:sidekiq][:args] = ["#{token[0...6]}*****#{token[-4..-1]}"]
        @bugsnag.call(notification)
      end
    end

    Bugsnag.configure do |c|
      c.middleware.use MetaDataMunger
    end

    notification = Bugsnag.notify(BugsnagTestException.new("It crashed"), {
      :sidekiq => {
        :args => ["abcdef123456abcdef123456abcdef123456"]
      }
    })

    expect(notification.meta_data[:sidekiq][:args]).to eq(["abcdef*****3456"])
  end

end
