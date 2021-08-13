# encoding: utf-8

require 'spec_helper'

require 'bugsnag/breadcrumbs/breadcrumb'

RSpec.describe Bugsnag::Breadcrumbs::Breadcrumb do
  describe "#name" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", nil, nil, nil)

      expect(breadcrumb.name).to eq("my message")
      expect(breadcrumb.message).to eq("my message")
    end

    it "can be accessed as #message" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", nil, nil, nil)

      breadcrumb.message = "my other message"
      expect(breadcrumb.message).to eq("my other message")
      expect(breadcrumb.name).to eq("my other message")

      breadcrumb.name = "another message"
      expect(breadcrumb.message).to eq("another message")
      expect(breadcrumb.name).to eq("another message")
    end
  end

  describe "#type" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, "test type", nil, nil)

      expect(breadcrumb.type).to eq("test type")
    end
  end

  describe "#meta_data" do
    it "is assigned in #initialize" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, {:a => 1, :b => 2}, nil)

      expect(breadcrumb.meta_data).to eq({:a => 1, :b => 2})
      expect(breadcrumb.metadata).to eq({:a => 1, :b => 2})
    end

    it "can be accessed as #metadata" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, { a: 1, b: 2 }, nil)

      breadcrumb.metadata = { c: 3 }
      expect(breadcrumb.meta_data).to eq({ c: 3 })
      expect(breadcrumb.metadata).to eq({ c: 3 })

      breadcrumb.meta_data = { d: 4 }
      expect(breadcrumb.meta_data).to eq({ d: 4 })
      expect(breadcrumb.metadata).to eq({ d: 4 })
    end
  end

  describe "#auto" do
    it "defaults to false" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, nil)

      expect(breadcrumb.auto).to eq(false)
    end

    it "is true if auto argument == :auto" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, :auto)

      expect(breadcrumb.auto).to eq(true)
    end

    it "is false if auto argument is anything else" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, :manual)

      expect(breadcrumb.auto).to eq(false)
    end
  end

  describe "#timestamp" do
    it "is stored as a timestamp" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(nil, nil, nil, nil)

      expect(breadcrumb.timestamp).to be_within(0.5).of Time.now.utc
    end
  end

  describe "#ignore?" do
    it "is not true by default" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)

      expect(breadcrumb.ignore?).to eq(false)
    end

    it "is able to be set" do
      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new("my message", "test type", {:a => 1, :b => 2}, :manual)
      breadcrumb.ignore!

      expect(breadcrumb.ignore?).to eq(true)
    end
  end

  describe "#to_h" do
    it "outputs as a hash" do
      fake_now = Time.gm(2020, 1, 2, 3, 4, 5, 123456)
      expect(Time).to receive(:now).and_return(fake_now)

      breadcrumb = Bugsnag::Breadcrumbs::Breadcrumb.new(
        "my message",
        "test type",
        { a: 1, b: 2 },
        :manual
      )

      expect(breadcrumb.to_h).to eq({
        name: "my message",
        type: "test type",
        metaData: {
          a: 1,
          b: 2
        },
        # This matches the time we stubbed earlier (fake_now)
        timestamp: "2020-01-02T03:04:05.123Z"
      })
    end
  end
end
