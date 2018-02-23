require "spec_helper"

describe Bugsnag::Middleware::Mailman do
  it "adds sinatra data to the metadata" do
    callback = double

    framework_versions = {}

    report = double("Bugsnag::Report")
    expect(report).to receive(:add_tab).with(:app, {
      :sinatraVersion => 'test'
    })
    expect(callback).to receive(:call).with(report)

    stub_const('::Sinatra::VERSION', 'test')

    middleware = Bugsnag::Middleware::Sinatra.new(callback)
    middleware.call(report)
  end
end
