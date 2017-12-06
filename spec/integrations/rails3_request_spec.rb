require 'spec_helper'

describe Bugsnag::Middleware::Rails3Request do
  before(:each) do
    Bugsnag.configuration.middleware.use(described_class)
  end

  describe "#call" do
    it "sets request metadata" do
      Bugsnag.configuration.set_request_data(:rack_env, {
        "action_dispatch.remote_ip" => "10.2.2.224",
        "action_dispatch.request_id" => "5",
      })
      Bugsnag.notify(BugsnagTestException.new('Grimbles'))

      expect(Bugsnag).to have_sent_notification { |payload|
        event = get_event_from_payload(payload)
        puts event["metaData"].inspect
        expect(event["metaData"]["request"]).to eq({
          "clientIp" => "10.2.2.224",
          "requestId" => "5"
        })
      }
    end

    context "the Remote IP will throw when serialized" do

      it "sets the client IP metdata to [SPOOF]" do
        class SpecialIP
          def to_s
            raise BugsnagTestException.new('oh no')
          end
        end
        Bugsnag.configuration.set_request_data(:rack_env, {
          "action_dispatch.remote_ip" => SpecialIP.new,
          "action_dispatch.request_id" => "5",
        })

        Bugsnag.notify(BugsnagTestException.new('Grimbles'))

        expect(Bugsnag).to have_sent_notification { |payload|
          event = get_event_from_payload(payload)
          puts event["metaData"].inspect
          expect(event["metaData"]["request"]).to eq({
            "clientIp" => "[SPOOF]",
            "requestId" => "5"
          })
        }
      end
    end
  end
end
