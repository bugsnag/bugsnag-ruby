require 'spec_helper'

describe Bugsnag::Rack do
  it "should call the upstream rack app with the environment" do
    rack_env = {"key" => "value"}
    app = lambda { |env| ['response', {}, env] }
    rack_stack = Bugsnag::Rack.new(app)
  
    response = rack_stack.call(rack_env)
  
    response.should be == ['response', {}, rack_env]
  end

  context "when an exception is raised in rack middleware" do
    # Build a fake crashing rack app
    exception = BugsnagTestException.new("It crashed")
    rack_env = {"key" => "value"}
    app = lambda { |env| raise exception }
    rack_stack = Bugsnag::Rack.new(app)

    it "should re-raise the exception" do
      expect { rack_stack.call(rack_env) }.to raise_error(BugsnagTestException)
    end

    it "should deliver an exception if auto_notify is enabled" do
      Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
        exception_class = payload[:events].first[:exceptions].first[:errorClass]
        exception_class.should be == exception.class.to_s
      end

      rack_stack.call(rack_env) rescue nil
    end
    
    it "should not deliver an exception if auto_notify is disabled" do
      Bugsnag.configure do |config|
        config.auto_notify = false
      end

      Bugsnag::Notification.should_not_receive(:deliver_exception_payload)

      rack_stack.call(rack_env) rescue nil
    end
  end
end