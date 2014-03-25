require 'spec_helper'

describe Bugsnag::MiddlewareStack do
  it "runs before_bugsnag_notify callbacks, adding a tab" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:some_tab]).not_to be_nil
      expect(event[:metaData][:some_tab][:info]).to eq("here")
      expect(event[:metaData][:some_tab][:data]).to eq("also here")
    end
    
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
  end
  
  it "runs before_bugsnag_notify callbacks, adding custom data" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:custom]).not_to be_nil
      expect(event[:metaData][:custom][:info]).to eq("here")
      expect(event[:metaData][:custom][:data]).to eq("also here")
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_custom_data(:info, "here")
      notif.add_custom_data(:data, "also here")
      
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(1)
  end

  it "runs before_bugsnag_notify callbacks, setting the user" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:user]).not_to be_nil
      expect(event[:user][:id]).to eq("here")
      expect(event[:user][:email]).to eq("also here")
      expect(event[:user][:name]).to eq("also here too")
      expect(event[:user][:random_key]).to eq("also here too too")
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.user = {:id => "here", :email => "also here", :name => "also here too", :random_key => "also here too too"}
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    expect(callback_run_count).to eq(1)
  end
  
  it "overrides data set in before_notify" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData][:custom]).not_to be_nil
      expect(event[:metaData][:custom][:info]).to eq("here2")
      expect(event[:metaData][:custom][:data]).to eq("also here")
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_custom_data(:info, "here")
      notif.add_custom_data(:data, "also here")
      
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:info => "here2"})
    expect(callback_run_count).to eq(1)
  end
  
  it "does not have have before or after callbacks by default" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      expect(event[:metaData].size).to eq(0)
    end
    
    expect(Bugsnag.before_notify_callbacks.size).to eq(0)
    expect(Bugsnag.after_notify_callbacks.size).to eq(0)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end
  
  it "runs after_bugsnag_notify callbacks" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload)
    
    callback_run_count = 0
    Bugsnag.after_notify_callbacks << lambda {|notif|
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    
    expect(callback_run_count).to eq(1)
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
end
