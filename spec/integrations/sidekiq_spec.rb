require 'spec_helper'
require 'sidekiq/testing'

class FailingWorker
  include Sidekiq::Worker
  def perform(value)
    puts "Work: #{100/value}"
  end
end

describe Bugsnag::Sidekiq do
  before do
    Sidekiq::Testing.inline!
    Sidekiq::Testing.server_middleware do |chain|
      chain.add Bugsnag::Sidekiq
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
