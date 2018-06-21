require 'spec_helper'
require 'sidekiq/testing'

class FailingWorker
  include Sidekiq::Worker
  def perform(value)
    puts "Work: #{100/value}"
  end
end

describe Bugsnag::Sidekiq do
  # Integration testing v3 is handled by maze as sidekiq doesnt
  # support error_handlers in testing mode
  context "integration tests in v2" do
    before do
      Sidekiq::Testing.inline!
      stub_const('Sidekiq::VERSION', '2.0.0')
      Sidekiq::Testing.server_middleware do |chain|
        chain.add ::Bugsnag::Sidekiq
      end
    end

    it "works" do
      begin
        FailingWorker.perform_async(-0)
        fail("shouldn't be here")
      rescue
      end

      expect(Bugsnag).to have_sent_notification {|payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["sidekiq"]["msg"]["class"]).to eq("FailingWorker")
        expect(event["metaData"]["sidekiq"]["msg"]["args"]).to eq([-0])
        expect(event["metaData"]["sidekiq"]["msg"]["queue"]).to eq("default")
        expect(event["severity"]).to eq("error")
      }
    end
  end

  context "initializing the integrations" do
    it "works in v2" do
      config = double
      expect(::Sidekiq).to receive(:configure_server).and_yield(config)
      stub_const('Sidekiq::VERSION', '2.0.0')

      chain = double
      expect(config).to receive(:server_middleware).and_yield(chain)
      expect(chain).to receive(:add).with(::Bugsnag::Sidekiq)

      load './lib/bugsnag/integrations/sidekiq.rb'
    end

    it "works in v3" do
      config = double
      expect(::Sidekiq).to receive(:configure_server).and_yield(config)
      stub_const('Sidekiq::VERSION', '3.0.0')

      error_handlers = []
      expect(config).to receive(:error_handlers).and_return(error_handlers)

      chain = double
      expect(config).to receive(:server_middleware).and_yield(chain)
      expect(chain).to receive(:add).with(::Bugsnag::Sidekiq)

      load './lib/bugsnag/integrations/sidekiq.rb'
      expect(error_handlers.size).to eq(1)
    end
  end
end
