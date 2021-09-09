require 'spec_helper'
require 'bugsnag/utility/metadata_delegate'

RSpec.describe Bugsnag::Utility::MetadataDelegate do
  context "#add_metadata" do
    context "with 'section', 'key' and 'value'" do
      it "adds the given key/value pair to the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = {}
        delegate.add_metadata(metadata, :abc, :xyz, "Hello!")

        expect(metadata).to eq({ abc: { xyz: "Hello!" } })
      end

      it "merges the new key/value pair with existing data in the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { abc: { a: 1, b: 2, c: 3 } }
        delegate.add_metadata(metadata, :abc, :xyz, "Hello!")

        expect(metadata).to eq({ abc: { a: 1, b: 2, c: 3, xyz: "Hello!" } })
      end

      it "replaces existing metadata if the 'key' already exists" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { abc: { xyz: "Hello!" } }
        delegate.add_metadata(metadata, :abc, :xyz, "Goodbye!")

        expect(metadata).to eq({ abc: { xyz: "Goodbye!" } })
      end

      it "removes the key if 'value' is nil" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { abc: { xyz: "Hello!" } }
        delegate.add_metadata(metadata, :abc, :xyz, nil)

        expect(metadata).to eq({ abc: {} })
      end
    end

    context "with 'section' and 'data'" do
      it "adds the data to the given section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = {}
        delegate.add_metadata(metadata, :xyz, { abc: "Hello!" })

        expect(metadata).to eq({ xyz: { abc: "Hello!" } })
      end

      it "merges the new data with any existing data in the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { xyz: { x: 1, y: 2, z: 3 } }
        delegate.add_metadata(metadata, :xyz, { abc: "Hello!" })

        expect(metadata).to eq({ xyz: { x: 1, y: 2, z: 3, abc: "Hello!" } })
      end

      it "does not deep merge conflicting data in the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { xyz: { x: { a: 1, b: 2 } } }
        delegate.add_metadata(metadata, :xyz, { x: { c: 3 } })

        # if this was a deep merge, metadata[:xyz][:x] would be { a: 1, b: 2, c: 3 }
        expect(metadata).to eq({ xyz: { x: { c: 3 } } })
      end

      it "replaces existing keys in the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { xyz: { x: 0, z: "yes", abc: "??" } }
        delegate.add_metadata(metadata, :xyz, { x: 1, y: 2, z: 3 })

        expect(metadata).to eq({ xyz: { x: 1, y: 2, z: 3, abc: "??" } })
      end

      it "removes keys that have a value of 'nil'" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = { xyz: { x: 0, z: "yes", abc: "??" } }
        delegate.add_metadata(metadata, :xyz, { x: nil, y: 2, z: 3 })

        expect(metadata).to eq({ xyz: { y: 2, z: 3, abc: "??" } })
      end
    end

    context "with bad parameters" do
      it "does nothing if called with a 'key' but no 'value'" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = {}
        delegate.add_metadata(metadata, :a, :b)

        expect(metadata).to be_empty
      end

      it "does nothing if called with a Hash 'key' and a value" do
        delegate = Bugsnag::Utility::MetadataDelegate.new

        metadata = {}
        delegate.add_metadata(metadata, :a, { b: 1 }, 123)

        expect(metadata).to be_empty
      end
    end
  end

  context "#clear_metadata" do
    context "with 'section'" do
      it "removes the given section from metadata" do
        delegate = Bugsnag::Utility::MetadataDelegate.new
        metadata = { some: "data", goes: "here" }

        delegate.clear_metadata(metadata, :some)

        expect(metadata).to eq({ goes: "here" })
      end

      it "does nothing if the section does not exist" do
        delegate = Bugsnag::Utility::MetadataDelegate.new
        metadata = { some: "data", goes: "here" }

        delegate.clear_metadata(metadata, :does_not_exist)

        expect(metadata).to eq({ some: "data", goes: "here" })
      end
    end

    context "with 'section' and 'key'" do
      it "removes the given 'key' from 'section'" do
        delegate = Bugsnag::Utility::MetadataDelegate.new
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        delegate.clear_metadata(metadata, :some, :data)

        expect(metadata).to eq({ some: { also: "there" } })
      end

      it "does nothing if the section does not exist" do
        delegate = Bugsnag::Utility::MetadataDelegate.new
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        delegate.clear_metadata(metadata, :nope, :data)

        expect(metadata).to eq({ some: { data: { goes: "here" }, also: "there" } })
      end

      it "does nothing if the key does not exist in the section" do
        delegate = Bugsnag::Utility::MetadataDelegate.new
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        delegate.clear_metadata(metadata, :some, :nah)

        expect(metadata).to eq({ some: { data: { goes: "here" }, also: "there" } })
      end
    end
  end
end
