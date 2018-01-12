require "spec_helper"

describe Bugsnag::Middleware::Mailman do
  it "adds mailman message to the metadata" do
    callback = double

    report = double("Bugsnag::Report") 
    expect(report).to receive(:request_data).and_return({
      :mailman_msg => "test message"
    })

    expect(report).to receive(:add_tab).with(:mailman, {
      "message" => "test message"
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::Mailman.new(callback)
    middleware.call(report)
  end
end
