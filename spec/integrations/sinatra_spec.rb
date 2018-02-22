require "spec_helper"

describe Bugsnag::Middleware::Mailman do
  it "adds sinatra data to the metadata" do
    callback = double

    framework_versions = {}

    report = double("Bugsnag::Report")
    expect(report).to receive(:app_framework_versions).and_return(framework_versions)

    expect(callback).to receive(:call).with(report)

    stub_const('::Sinatra::VERSION', 'test')

    middleware = Bugsnag::Middleware::Sinatra.new(callback)
    middleware.call(report)

    expect(framework_versions).to eq({:sinatraVersion => 'test'})
  end
end
