require 'spec_helper'

# shared examples for #add_metadata and #clear_metadata
# use by providing two functions - one that implements add_metadata and one
# that implements clear_metadata, e.g.
#
#   RSpec.describe SomeClass do
#     include_examples(
#       'metadata delegate',
#       ->(metadata, *args) { SomeClass.new(metadata).add_metadata(*args) },
#       ->(metadata, *args) { SomeClass.new(metadata).clear_metadata(*args) }
#     )
#   end
RSpec.shared_examples 'metadata delegate' do |add_metadata, clear_metadata|
  context "#add_metadata" do
    context "with 'section', 'key' and 'value'" do
      it "adds the given key/value pair to the section" do
        metadata = {}

        add_metadata.call(metadata, :abc, :xyz, "Hello!")

        expect(metadata).to eq({ abc: { xyz: "Hello!" } })
      end

      it "merges the new key/value pair with existing data in the section" do
        metadata = { abc: { a: 1, b: 2, c: 3 } }

        add_metadata.call(metadata, :abc, :xyz, "Hello!")

        expect(metadata).to eq({ abc: { a: 1, b: 2, c: 3, xyz: "Hello!" } })
      end

      it "replaces existing metadata if the 'key' already exists" do
        metadata = { abc: { xyz: "Hello!" } }

        add_metadata.call(metadata, :abc, :xyz, "Goodbye!")

        expect(metadata).to eq({ abc: { xyz: "Goodbye!" } })
      end

      it "removes the key if 'value' is nil" do
        metadata = { abc: { xyz: "Hello!" } }

        add_metadata.call(metadata, :abc, :xyz, nil)

        expect(metadata).to eq({ abc: {} })
      end
    end

    context "with 'section' and 'data'" do
      it "adds the data to the given section" do
        metadata = {}

        add_metadata.call(metadata, :xyz, { abc: "Hello!" })

        expect(metadata).to eq({ xyz: { abc: "Hello!" } })
      end

      it "merges the new data with any existing data in the section" do
        metadata = { xyz: { x: 1, y: 2, z: 3 } }

        add_metadata.call(metadata, :xyz, { abc: "Hello!" })

        expect(metadata).to eq({ xyz: { x: 1, y: 2, z: 3, abc: "Hello!" } })
      end

      it "does not deep merge conflicting data in the section" do
        metadata = { xyz: { x: { a: 1, b: 2 } } }

        add_metadata.call(metadata, :xyz, { x: { c: 3 } })

        # if this was a deep merge, metadata[:xyz][:x] would be { a: 1, b: 2, c: 3 }
        expect(metadata).to eq({ xyz: { x: { c: 3 } } })
      end

      it "replaces existing keys in the section" do
        metadata = { xyz: { x: 0, z: "yes", abc: "??" } }

        add_metadata.call(metadata, :xyz, { x: 1, y: 2, z: 3 })

        expect(metadata).to eq({ xyz: { x: 1, y: 2, z: 3, abc: "??" } })
      end

      it "removes keys that have a value of 'nil'" do
        metadata = { xyz: { x: 0, z: "yes", abc: "??" } }

        add_metadata.call(metadata, :xyz, { x: nil, y: 2, z: 3 })

        expect(metadata).to eq({ xyz: { y: 2, z: 3, abc: "??" } })
      end
    end

    context "with bad parameters" do
      it "does nothing if called with a 'key' but no 'value'" do
        metadata = {}

        add_metadata.call(metadata, :a, :b)

        expect(metadata).to be_empty
      end

      it "does nothing if called with a Hash 'key' and a value" do
        metadata = {}

        add_metadata.call(metadata, :a, { b: 1 }, 123)

        expect(metadata).to be_empty
      end
    end
  end

  context "#clear_metadata" do
    context "with 'section'" do
      it "removes the given section from metadata" do
        metadata = { some: "data", goes: "here" }

        clear_metadata.call(metadata, :some)

        expect(metadata).to eq({ goes: "here" })
      end

      it "does nothing if the section does not exist" do
        metadata = { some: "data", goes: "here" }

        clear_metadata.call(metadata, :does_not_exist)

        expect(metadata).to eq({ some: "data", goes: "here" })
      end
    end

    context "with 'section' and 'key'" do
      it "removes the given 'key' from 'section'" do
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        clear_metadata.call(metadata, :some, :data)

        expect(metadata).to eq({ some: { also: "there" } })
      end

      it "does nothing if the section does not exist" do
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        clear_metadata.call(metadata, :nope, :data)

        expect(metadata).to eq({ some: { data: { goes: "here" }, also: "there" } })
      end

      it "does nothing if the key does not exist in the section" do
        metadata = { some: { data: { goes: "here" }, also: "there" } }

        clear_metadata.call(metadata, :some, :nah)

        expect(metadata).to eq({ some: { data: { goes: "here" }, also: "there" } })
      end
    end
  end
end
