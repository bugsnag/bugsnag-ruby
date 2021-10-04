require "spec_helper"

require "bugsnag/endpoint_configuration"

describe Bugsnag::EndpointConfiguration do
  it "has notify & session URLs" do
    configuration = Bugsnag::EndpointConfiguration.new("notify", "session")

    expect(configuration.notify).to eq("notify")
    expect(configuration.sessions).to eq("session")
  end

  it "is immutable" do
    configuration = Bugsnag::EndpointConfiguration.new("notify", "session")

    expect(configuration).not_to respond_to(:notify=)
    expect(configuration).not_to respond_to(:session=)
  end
end
