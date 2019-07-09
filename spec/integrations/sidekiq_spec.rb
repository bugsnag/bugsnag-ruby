require 'spec_helper'
require 'sidekiq'
require 'sidekiq/testing'

class Worker
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
      expect{ Worker.perform_async(-0) }.to raise_error(ZeroDivisionError)

      expect(Bugsnag).to have_sent_notification {|payload, headers|
        event = get_event_from_payload(payload)
        expect(event["metaData"]["sidekiq"]["msg"]["class"]).to eq("Worker")
        expect(event["metaData"]["sidekiq"]["msg"]["args"]).to eq([-0])
        expect(event["metaData"]["sidekiq"]["msg"]["queue"]).to eq("default")
        expect(event["severity"]).to eq("error")
        expect(event["app"]["type"]).to eq("sidekiq")
        expect(event["device"]["runtimeVersions"]["sidekiq"]).to eq(::Sidekiq::VERSION)
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

  context "ensuring data reset" do
    context "v2" do
      before do
        Sidekiq::Testing.inline!
        stub_const('Sidekiq::VERSION', '2.0.0')
        Sidekiq::Testing.server_middleware do |chain|
          chain.add ::Bugsnag::Sidekiq
        end
      end

      it "resets with an exception" do
        expect(Bugsnag.configuration).to receive(:set_request_data).with(:sidekiq, hash_including(:queue => "default"))
        expect(Bugsnag.configuration).to receive(:clear_request_data).at_least(:once)
        expect{ Worker.perform_async(-0) }.to raise_error(ZeroDivisionError)
      end

      it "resets without an exception" do
        expect(Bugsnag.configuration).to receive(:set_request_data).with(:sidekiq, hash_including(:queue => "default"))
        expect(Bugsnag.configuration).to receive(:clear_request_data).at_least(:once)
        expect{ Worker.perform_async(1) }.to_not raise_error
      end
    end

    context "v3" do
      before do
        Sidekiq::Testing.inline!
        stub_const('Sidekiq::VERSION', '3.0.0')
        Sidekiq::Testing.server_middleware do |chain|
          chain.add ::Bugsnag::Sidekiq
        end
      end

      it "doesn't reset with an exception" do
        # This test ensures that when an exception occurs the request data isn't immediately reset
        expect(Bugsnag.configuration).to receive(:set_request_data).with(:sidekiq, hash_including(:queue => "default"))
        # Always received once due to the spec_helper setup
        expect(Bugsnag.configuration).to receive(:clear_request_data).once
        expect{ Worker.perform_async(-0) }.to raise_error(ZeroDivisionError)
      end

      it "resets without an exception" do
        expect(Bugsnag.configuration).to receive(:set_request_data).with(:sidekiq, hash_including(:queue => "default"))
        expect(Bugsnag.configuration).to receive(:clear_request_data).twice
        expect{ Worker.perform_async(1) }.to_not raise_error
      end

      it "always resets in the error handler" do
        config = double
        allow(::Sidekiq).to receive(:configure_server).and_yield(config)

        error_handlers = []
        allow(config).to receive(:error_handlers).and_return(error_handlers)

        chain = double
        allow(config).to receive(:server_middleware).and_yield(chain)
        allow(chain).to receive(:add).with(::Bugsnag::Sidekiq)

        Bugsnag::Sidekiq.configure_server(config)

        expect(error_handlers.size).to equal(1)

        ex = double
        expect(Bugsnag::Sidekiq).to receive(:notify).with(ex)
        expect(Bugsnag.configuration).to receive(:clear_request_data).twice

        error_handlers[0].call(ex)
      end
    end
  end
end
