require 'spec_helper'

describe Bugsnag::FeatureFlag do
  it "has a name" do
    flag = Bugsnag::FeatureFlag.new("abc")

    expect(flag.name).to eq("abc")
    expect(flag.variant).to be_nil
  end

  it "has an optional variant" do
    flag = Bugsnag::FeatureFlag.new("abc", "xyz")

    expect(flag.name).to eq("abc")
    expect(flag.variant).to eq("xyz")
  end

  [
    [123, "123"],
    [true, "true"],
    [false, "false"],
    [[1, 2, 3], "[1, 2, 3]"],
    [{ a: 1, b: 2 }, "{:a=>1, :b=>2}"],
  ].each do |variant, expected|
    it "converts the variant to a string if given '#{variant.class}'" do
      flag = Bugsnag::FeatureFlag.new("abc", variant)

      expect(flag.name).to eq("abc")
      expect(flag.variant).to eq(expected)
    end
  end

  it "sets variant to 'nil' if variant cannot be converted to a string" do
    class StringRaiser
      def to_s
        raise 'Oh no you do not!'
      end
    end

    flag = Bugsnag::FeatureFlag.new("abc", StringRaiser.new)

    expect(flag.name).to eq("abc")
    expect(flag.variant).to be_nil
  end


  it "is immutable" do
    flag = Bugsnag::FeatureFlag.new("abc", "xyz")

    expect(flag).not_to respond_to(:name=)
    expect(flag).not_to respond_to(:variant=)
  end

  describe "#to_h" do
    it "converts the flag to a hash when no variant is given" do
      flag = Bugsnag::FeatureFlag.new("xyz")

      expect(flag.to_h).to eq({ "featureFlag" => "xyz" })
    end

    it "converts the flag to a hash when variant is given" do
      flag = Bugsnag::FeatureFlag.new("xyz", "1234")

      expect(flag.to_h).to eq({ "featureFlag" => "xyz", "variant" => "1234" })
    end
  end

  describe "#==" do
    it "is equal to other instances with the same name when neither have a variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz")
      flag2 = Bugsnag::FeatureFlag.new("xyz")

      expect(flag1).to eq(flag2)
      expect(flag2).to eq(flag1)

      expect(flag1).not_to be(flag2)
    end

    it "is equal to other instances with the same name and variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz", "1234")
      flag2 = Bugsnag::FeatureFlag.new("xyz", "1234")

      expect(flag1).to eq(flag2)
      expect(flag2).to eq(flag1)

      expect(flag1).not_to be(flag2)
    end

    it "is not equal to other instances with the same name but a different variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz", "1234")
      flag2 = Bugsnag::FeatureFlag.new("xyz", "9876")

      expect(flag1).not_to eq(flag2)
      expect(flag2).not_to eq(flag1)
    end

    it "is not equal to other instances with the same name when only one has a variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz")
      flag2 = Bugsnag::FeatureFlag.new("xyz", "9876")

      expect(flag1).not_to eq(flag2)
      expect(flag2).not_to eq(flag1)
    end

    it "is not equal to other instances with a different name but the same variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz", "1234")
      flag2 = Bugsnag::FeatureFlag.new("abc", "1234")

      expect(flag1).not_to eq(flag2)
      expect(flag2).not_to eq(flag1)
    end

    it "is not equal to other instances with a different name and variant" do
      flag1 = Bugsnag::FeatureFlag.new("xyz", "1234")
      flag2 = Bugsnag::FeatureFlag.new("abc", "9876")

      expect(flag1).not_to eq(flag2)
      expect(flag2).not_to eq(flag1)
    end
  end
end
