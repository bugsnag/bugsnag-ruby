# encoding: utf-8

require 'spec_helper'
require 'bugsnag/utility/circular_buffer'

describe Bugsnag::Utility::CircularBuffer do
  describe "buffer size" do
    it "should be 25 by default" do
      buffer = Bugsnag::Utility::CircularBuffer.new

      expect(buffer.max_items).to equal 25
    end

    it "can be set during initialization" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)

      expect(buffer.max_items).to equal 10
    end

    it "can be changed using max_items =" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)
      buffer.max_items = 17

      expect(buffer.max_items).to equal(17)
    end
  end

  describe "buffer items" do
    it "initializes empty" do
      buffer = Bugsnag::Utility::CircularBuffer.new

      expect(buffer.to_a).to eq([])
    end

    it "can be added to with <<" do
      buffer = Bugsnag::Utility::CircularBuffer.new
      buffer << 1
      expect(buffer.to_a).to eq([1])
    end

    it "are shifted when max_items are exceeded" do
      buffer = Bugsnag::Utility::CircularBuffer.new(5)
      (0...10).each { |x| buffer << x }

      expect(buffer.to_a).to eq([5, 6, 7, 8, 9])
    end

    it "are removed if max_items is reduced" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)
      (0...10).each { |x| buffer << x }
      buffer.max_items = 3

      expect(buffer.to_a).to eq([7, 8, 9])
    end

    it "can be inserted in chains" do
      buffer = Bugsnag::Utility::CircularBuffer.new
      buffer << 1 << 2 << 3 << 4 << 5

      expect(buffer.to_a).to eq([1, 2, 3, 4, 5])
    end

    it "can be iterated over" do
      buffer = Bugsnag::Utility::CircularBuffer.new
      buffer << 1
      buffer << 2
      buffer << 3

      output = []
      buffer.each do |x|
        output << x
      end

      expect(output).to eq([1, 2, 3])
    end

    it "respects max_items when increased" do
      buffer = Bugsnag::Utility::CircularBuffer.new(3)
      buffer << 1
      buffer << 2
      buffer << 3

      expect(buffer.to_a).to eq([1, 2, 3])

      buffer.max_items = 5
      buffer << 4
      buffer << 5

      expect(buffer.to_a).to eq([1, 2, 3, 4, 5])
    end
  end
end