require 'spec_helper'

describe Bugsnag::MiddlewareStack do
  it "should run before_bugsnag_notify callbacks, adding a tab" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:some_tab].should_not be_nil
      event[:metaData][:some_tab][:info].should be == "here"
      event[:metaData][:some_tab][:data].should be == "also here"
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
    callback_run_count.should be == 1
  end
  
  it "should run before_bugsnag_notify callbacks, adding custom data" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:custom].should_not be_nil
      event[:metaData][:custom][:info].should be == "here"
      event[:metaData][:custom][:data].should be == "also here"
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_custom_data(:info, "here")
      notif.add_custom_data(:data, "also here")
      
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    callback_run_count.should be == 1
  end

  it "should run before_bugsnag_notify callbacks, setting the user" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:user].should_not be_nil
      event[:user][:id].should be == "here"
      event[:user][:email].should be == "also here"
      event[:user][:name].should be == "also here too"
      event[:user][:random_key].should be == "also here too too"
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.user = {:id => "here", :email => "also here", :name => "also here too", :random_key => "also here too too"}
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    callback_run_count.should be == 1
  end
  
  it "overrides should override data set in before_notify" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData][:custom].should_not be_nil
      event[:metaData][:custom][:info].should be == "here2"
      event[:metaData][:custom][:data].should be == "also here"
    end
    
    callback_run_count = 0
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_custom_data(:info, "here")
      notif.add_custom_data(:data, "also here")
      
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"), {:info => "here2"})
    callback_run_count.should be == 1
  end
  
  it "should have no before or after callbacks by default" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
      event[:metaData].should have(0).items
    end
    
    Bugsnag.before_notify_callbacks.should have(0).items
    Bugsnag.after_notify_callbacks.should have(0).items
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end
  
  it "should run after_bugsnag_notify callbacks" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      event = get_event_from_payload(payload)
    end
    
    callback_run_count = 0
    Bugsnag.after_notify_callbacks << lambda {|notif|
      callback_run_count += 1
    }

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    
    callback_run_count.should be == 1
  end

  it "should not execute disabled bugsnag middleware" do
    callback_run_count = 0
    Bugsnag.configure do |config|
      config.middleware.disable(Bugsnag::Middleware::Callbacks)
    end
    
    Bugsnag.before_notify_callbacks << lambda {|notif|
      callback_run_count += 1
    }
    
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
    callback_run_count.should be == 0
  end
end