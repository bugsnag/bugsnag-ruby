require "spec_helper"

describe Bugsnag::Middleware::ClearanceUser do
  it "updates the reports user with warden parameters" do
    callback = double

    user = double
    allow(user).to receive_messages(
      :email => "TEST_EMAIL",
      :name => "TEST_NAME",
      :created_at => "TEST_NOW"
    )

    clearance = double
    allow(clearance).to receive_messages(
      :signed_in? => true,
      :current_user => user
    )

    report = double("Bugsnag::Report") 
    expect(report).to receive(:request_data).exactly(5).times.and_return({
      :rack_env => {
        :clearance => clearance
      }
    })

    expect(report).to receive(:user=).with({
      :email => "TEST_EMAIL",
      :name => "TEST_NAME",
      :created_at => "TEST_NOW"
    })

    expect(callback).to receive(:call).with(report)

    middleware = Bugsnag::Middleware::ClearanceUser.new(callback)
    middleware.call(report)
  end
end
