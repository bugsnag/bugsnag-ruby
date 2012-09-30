require 'spec_helper'
require 'securerandom'

describe Bugsnag::MiddlewareStack do
  it "should contain an api_key if one is set" do
    Bugsnag::Notification.should_receive(:deliver_exception_payload) do |endpoint, payload|
      payload[:apiKey].should be == "c9d60ae4c7e70c4b6c4ebd3e8056d2b8"
    end

    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end
end