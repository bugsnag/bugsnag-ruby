require 'spec_helper'
require 'bugsnag/utility/duplicator'

# NOTE: RSpec will freeze when trying to print the diff of recursive objects
#       to avoid this, we use a custom "have_the_same_id_as" matcher and must
#       not use the built-in "to eq", "to be" etc...
RSpec.describe Bugsnag::Utility::Duplicator do
  subject(:duplicator) { Bugsnag::Utility::Duplicator }

  describe "simple values" do
    it "does not copy symbols" do
      symbol = :abc
      expect(duplicator.duplicate(symbol)).to have_the_same_id_as(symbol)
    end

    it "does not copy integers" do
      integer = 123
      expect(duplicator.duplicate(integer)).to have_the_same_id_as(integer)
    end

    it "does not copy floats" do
      float = 2.3
      expect(duplicator.duplicate(float)).to have_the_same_id_as(float)
    end

    it "does not copy rationals" do
      rational = 45.67.to_r
      expect(duplicator.duplicate(rational)).to have_the_same_id_as(rational)
    end

    it "does not copy methods" do
      subject_method = method(:subject)
      expect(duplicator.duplicate(subject_method)).to have_the_same_id_as(subject_method)
    end

    it "does not copy true" do
      true_value = true
      expect(duplicator.duplicate(true_value)).to have_the_same_id_as(true_value)
    end

    it "does not copy false" do
      false_value = false
      expect(duplicator.duplicate(false_value)).to have_the_same_id_as(false_value)
    end

    it "does not copy nil" do
      nil_value = nil
      expect(duplicator.duplicate(nil_value)).to have_the_same_id_as(nil_value)
    end

    it "does not copy BasicObjects" do
      object = BasicObject.new
      expect(duplicator.duplicate(object)).to have_the_same_id_as(object)
    end

    it "copys strings" do
      string = "hello"
      copy = duplicator.duplicate(string)

      expect(copy).not_to have_the_same_id_as(string)

      copy.upcase!

      expect(string).to eq("hello")
      expect(copy).to eq("HELLO")
    end

    it "copys Objects" do
      object = Object.new
      object.instance_variable_set(:@abc, "hello")

      copy = duplicator.duplicate(object)

      expect(copy).to_not have_the_same_id_as(object)
      expect(copy.instance_variable_get(:@abc)).not_to have_the_same_id_as(object.instance_variable_get(:@abc))

      copy.instance_variable_set(:@xyz, 123)

      expect(copy.instance_variable_get(:@xyz)).to be(123)
      expect(object.instance_variable_defined?(:@xyz)).to be(false)
      expect(object.instance_variable_get(:@xyz)).to be(nil)
    end

    it "copys Structs" do
      struct_for_testing = Struct.new(:name, :sound)

      object = struct_for_testing.new("Rover", "bark")
      copy = duplicator.duplicate(object)

      expect(copy).not_to have_the_same_id_as(object)

      copy.name.downcase!
      copy.sound.upcase!

      expect(copy.name).to eq("rover")
      expect(copy.sound).to eq("BARK")

      expect(object.name).to eq("Rover")
      expect(object.sound).to eq("bark")
    end

    it "copys frozen Structs" do
      struct_for_testing = Struct.new(:name, :sound)

      object = struct_for_testing.new("Rover", "bark").freeze
      copy = duplicator.duplicate(object)

      expect(copy).not_to have_the_same_id_as(object)

      copy.name.downcase!
      copy.sound.upcase!

      expect(copy.name).to eq("rover")
      expect(copy.sound).to eq("BARK")

      expect(object.name).to eq("Rover")
      expect(object.sound).to eq("bark")
    end

    it "copys Ranges" do
      range = "a".."z"
      copy = duplicator.duplicate(range)

      expect(copy).not_to have_the_same_id_as(range)

      copy.first.upcase!

      expect(copy.first).to eq("A")
      expect(range.first).to eq("a")

      # the size is 58 because it includes punctuation between "Z" and "a" (ASCII 91-96)
      expect(copy.to_a.size).to eq(58)
      expect(range.to_a.size).to eq(26)
    end

    it "copys a custom class" do
      class ExampleClassForTesting
        attr_accessor :one, :two, :three

        def initialize(one, two, three)
          @one = one
          @two = two
          @three = three
        end
      end

      original = ExampleClassForTesting.new(["a", "b", ["c", "d"]], { abc: "xyz" }, 3)

      copy = duplicator.duplicate(original)

      expect(copy).not_to have_the_same_id_as(original)

      copy.one[1].upcase!
      copy.one[2].push("e", "f")
      copy.two[:abc].upcase!

      expect(copy.one[1]).to eq("B")
      expect(original.one[1]).to eq("b")

      expect(copy.one[2].length).to eq(4)
      expect(original.one[2].length).to eq(2)

      expect(copy.two[:abc]).to eq("XYZ")
      expect(original.two[:abc]).to eq("xyz")

      copy.three = 6

      expect(copy.three).to eq(6)
      expect(original.three).to eq(3)
    end
  end

  describe "arrays" do
    it "copys arrays and any duplicatable values within them" do
      array = [1, "a", nil, Object.new]

      copy = duplicator.duplicate(array)

      expect(copy).not_to have_the_same_id_as(array)

      expect(copy[0]).to have_the_same_id_as(array[0])
      expect(copy[1]).not_to have_the_same_id_as(array[1])
      expect(copy[2]).to have_the_same_id_as(array[2])
      expect(copy[3]).not_to have_the_same_id_as(array[3])
    end

    it "copys nested arrays" do
      sub_array = [2, "b"]
      array = [1, "a", sub_array]

      copy = duplicator.duplicate(array)
      sub_array_copy = copy.last

      expect(copy).not_to have_the_same_id_as(array)
      expect(sub_array_copy).not_to have_the_same_id_as(sub_array)

      copy[1].upcase!
      sub_array_copy[1].upcase!

      expect(copy[0]).to eq(1)
      expect(array[0]).to eq(1)
      expect(copy[1]).to eq("A")
      expect(array[1]).to eq("a")

      expect(sub_array_copy[0]).to eq(2)
      expect(sub_array[0]).to eq(2)
      expect(sub_array_copy[1]).to eq("B")
      expect(sub_array[1]).to eq("b")
    end

    it "handles recursive arrays" do
      array = [1, "a", nil, Object.new]
      array.push(array)

      copy = duplicator.duplicate(array)

      expect(copy).not_to have_the_same_id_as(array)

      # the recursive array should resolve to itself, not a separate copy
      expect(copy.last).to have_the_same_id_as(copy)
      expect(copy.last.last).to have_the_same_id_as(copy)
    end
  end

  describe "hashes" do
    it "copys hashes and any duplicatable values within them" do
      hash = { a: 123, b: "yes", c: Object.new }

      copy = duplicator.duplicate(hash)

      expect(copy).not_to have_the_same_id_as(hash)

      expect(copy[:a]).to have_the_same_id_as(hash[:a])
      expect(copy[:b]).not_to have_the_same_id_as(hash[:b])
      expect(copy[:c]).not_to have_the_same_id_as(hash[:c])

      copy[:b].upcase!
      copy[:c].instance_variable_set(:@hello, "world")

      expect(copy[:b]).to eq("YES")
      expect(hash[:b]).to eq("yes")

      expect(copy[:c].instance_variable_get(:@hello)).to eq("world")
      expect(hash[:c].instance_variable_get(:@hello)).to eq(nil)
    end

    it "copys nested hashes" do
      hash = { a: { b: { c: "hello" } } }

      copy = duplicator.duplicate(hash)

      expect(copy).not_to have_the_same_id_as(hash)

      expect(copy[:a]).not_to have_the_same_id_as(hash[:a])
      expect(copy[:a][:b]).not_to have_the_same_id_as(hash[:a][:b])
      expect(copy[:a][:b][:c]).not_to have_the_same_id_as(hash[:a][:b][:c])

      copy[:a][:b][:c].upcase!

      expect(copy[:a][:b][:c]).to eq("HELLO")
      expect(hash[:a][:b][:c]).to eq("hello")
    end

    it "copys frozen hashes" do
      hash = { a: 123, b: "yes", c: Object.new }.freeze

      copy = duplicator.duplicate(hash)

      expect(copy).not_to have_the_same_id_as(hash)

      expect(copy[:a]).to have_the_same_id_as(hash[:a])
      expect(copy[:b]).not_to have_the_same_id_as(hash[:b])
      expect(copy[:c]).not_to have_the_same_id_as(hash[:c])

      copy[:b].upcase!
      copy[:c].instance_variable_set(:@hello, "world")

      expect(copy[:b]).to eq("YES")
      expect(hash[:b]).to eq("yes")

      expect(copy[:c].instance_variable_get(:@hello)).to eq("world")
      expect(hash[:c].instance_variable_get(:@hello)).to eq(nil)
    end

    it "handles recursive hashes" do
      hash = { abc: 123 }
      hash[:me] = hash

      copy = duplicator.duplicate(hash)

      expect(copy).not_to have_the_same_id_as(hash)
      expect(copy[:me]).not_to have_the_same_id_as(hash[:me])
      expect(copy[:me][:me]).not_to have_the_same_id_as(hash[:me][:me])

      expect(copy[:abc]).to eq(123)
      expect(copy[:me][:me][:abc]).to eq(123)
    end
  end
end
