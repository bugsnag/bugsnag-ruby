require 'spec_helper'

describe Bugsnag::Utility::FeatureFlagDelegate do
  invalid_names = [
    nil,
    true,
    false,
    1234,
    [1, 2, 3],
    { a: 1, b: 2 },
    "",
  ]

  it "contains no flags by default" do
    delegate = Bugsnag::Utility::FeatureFlagDelegate.new

    expect(delegate.as_json).to eq([])
  end

  describe "#add" do
    it "can add flags individually" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.add("another", nil)
      delegate.add("a third one", "1234")

      expect(delegate.as_json).to eq([
        { "featureFlag" => "abc", "variant" => "xyz" },
        { "featureFlag" => "another" },
        { "featureFlag" => "a third one", "variant" => "1234" },
      ])
    end

    it "replaces flags by name when the original has no variant" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", nil)
      delegate.add("another", nil)
      delegate.add("abc", "123")

      expect(delegate.as_json).to eq([
        { "featureFlag" => "abc", "variant" => "123" },
        { "featureFlag" => "another" },
      ])
    end

    it "replaces flags by name when the replacement has no variant" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "123")
      delegate.add("another", nil)
      delegate.add("abc", nil)

      expect(delegate.as_json).to eq([
        { "featureFlag" => "abc" },
        { "featureFlag" => "another" },
      ])
    end

    it "replaces flags by name when both have variants" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "123")
      delegate.add("another", nil)
      delegate.add("abc", "987")

      expect(delegate.as_json).to eq([
        { "featureFlag" => "abc", "variant" => "987" },
        { "featureFlag" => "another" },
      ])
    end

    invalid_names.each do |name|
      it "drops flags when name is '#{name.inspect}'" do
        delegate = Bugsnag::Utility::FeatureFlagDelegate.new

        delegate.add("abc", "123")
        delegate.add(name, nil)
        delegate.add("xyz", "987")

        expect(delegate.as_json).to eq([
          { "featureFlag" => "abc", "variant" => "123" },
          { "featureFlag" => "xyz", "variant" => "987" },
        ])
      end
    end
  end

  describe "#merge" do
    it "can add multiple flags at once" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.merge([
        Bugsnag::FeatureFlag.new("a", "xyz"),
        Bugsnag::FeatureFlag.new("b"),
        Bugsnag::FeatureFlag.new("c", "111"),
        Bugsnag::FeatureFlag.new("d"),
      ])

      expect(delegate.as_json).to eq([
        { "featureFlag" => "a", "variant" => "xyz" },
        { "featureFlag" => "b" },
        { "featureFlag" => "c", "variant" => "111" },
        { "featureFlag" => "d" },
      ])
    end

    it "replaces flags by name when the original has no variant" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("a", nil)

      delegate.merge([
        Bugsnag::FeatureFlag.new("b"),
        Bugsnag::FeatureFlag.new("a", "123"),
      ])

      expect(delegate.as_json).to eq([
        { "featureFlag" => "a", "variant" => "123" },
        { "featureFlag" => "b" },
      ])
    end

    it "replaces flags by name when the replacement has no variant" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("a", "123")

      delegate.merge([
        Bugsnag::FeatureFlag.new("b"),
        Bugsnag::FeatureFlag.new("a"),
      ])

      expect(delegate.as_json).to eq([
        { "featureFlag" => "a" },
        { "featureFlag" => "b" },
      ])
    end

    it "replaces flags by name when both have variants" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("a", "987")

      delegate.merge([
        Bugsnag::FeatureFlag.new("b"),
        Bugsnag::FeatureFlag.new("a", "123"),
      ])

      expect(delegate.as_json).to eq([
        { "featureFlag" => "a", "variant" => "123" },
        { "featureFlag" => "b" },
      ])
    end

    it "ignores anything that isn't a FeatureFlag instance" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.merge([
        Bugsnag::FeatureFlag.new("a", "xyz"),
        1234,
        Bugsnag::FeatureFlag.new("b"),
        "hello",
        Bugsnag::FeatureFlag.new("c", "111"),
        RuntimeError.new("xyz"),
        Bugsnag::FeatureFlag.new("d"),
        nil,
      ])

      expect(delegate.as_json).to eq([
        { "featureFlag" => "a", "variant" => "xyz" },
        { "featureFlag" => "b" },
        { "featureFlag" => "c", "variant" => "111" },
        { "featureFlag" => "d" },
      ])
    end

    invalid_names.each do |name|
      it "drops flag when name is '#{name.inspect}'" do
        delegate = Bugsnag::Utility::FeatureFlagDelegate.new

        delegate.merge([
          Bugsnag::FeatureFlag.new("abc", "123"),
          Bugsnag::FeatureFlag.new(name, "456"),
          Bugsnag::FeatureFlag.new("xyz", "789"),
        ])

        expect(delegate.as_json).to eq([
          { "featureFlag" => "abc", "variant" => "123" },
          { "featureFlag" => "xyz", "variant" => "789" },
        ])
      end
    end
  end

  describe "#remove" do
    it "can remove flags by name" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.add("another", nil)
      delegate.add("a third one", "1234")

      delegate.remove("abc")
      delegate.remove("a third one")

      expect(delegate.as_json).to eq([
        { "featureFlag" => "another" },
      ])
    end

    it "does nothing when no flag exists with the given name" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.remove("xyz")

      expect(delegate.as_json).to eq([
        { "featureFlag" => "abc", "variant" => "xyz" },
      ])
    end
  end

  describe "#clear" do
    it "can remove all flags at once" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.add("another", nil)
      delegate.add("a third one", "1234")

      delegate.clear

      expect(delegate.as_json).to eq([])
    end

    it "does nothing when there are no flags" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.clear

      expect(delegate.as_json).to eq([])
    end
  end

  describe "#to_a" do
    it "returns an empty array when there are no feature flags" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      expect(delegate.to_a).to eq([])
    end

    it "returns an array of feature flags" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.add("another", nil)
      delegate.add("a third one", "1234")

      expect(delegate.to_a).to eq([
        Bugsnag::FeatureFlag.new("abc", "xyz"),
        Bugsnag::FeatureFlag.new("another"),
        Bugsnag::FeatureFlag.new("a third one", "1234"),
      ])
    end

    it "can be mutated without affecting the internal storage" do
      delegate = Bugsnag::Utility::FeatureFlagDelegate.new

      delegate.add("abc", "xyz")
      delegate.add("another", nil)
      delegate.add("a third one", "1234")

      flags = delegate.to_a

      expected = [
        Bugsnag::FeatureFlag.new("abc", "xyz"),
        Bugsnag::FeatureFlag.new("another"),
        Bugsnag::FeatureFlag.new("a third one", "1234"),
      ]

      expect(flags).to eq(expected)

      flags.pop
      flags.pop
      flags.push(1234)

      expect(delegate.to_a).to eq(expected)
      expect(flags).to eq([
        Bugsnag::FeatureFlag.new("abc", "xyz"),
        1234,
      ])
    end
  end
end
