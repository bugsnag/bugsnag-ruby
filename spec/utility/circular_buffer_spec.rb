# encoding: utf-8

require 'spec_helper'
require 'bugsnag/utility/circular_buffer'

RSpec.describe Bugsnag::Utility::CircularBuffer do
  describe "#initialize" do
    it "contains no items" do
      buffer = Bugsnag::Utility::CircularBuffer.new

      expect(buffer.to_a).to eq([])
    end
  end

  describe "#max_items" do
    it "defaults to 25" do
      buffer = Bugsnag::Utility::CircularBuffer.new

      expect(buffer.max_items).to equal 25
    end

    it "can be set during #initialize" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)

      expect(buffer.max_items).to equal 10
    end
  end

  describe "#max_items=" do
    it "changes #max_items" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)
      buffer.max_items = 17

      expect(buffer.max_items).to equal(17)
    end

    it "shifts any excess items when reduced" do
      buffer = Bugsnag::Utility::CircularBuffer.new(10)
      (0...10).each { |x| buffer << x }
      buffer.max_items = 3

      expect(buffer.to_a).to eq([7, 8, 9])
    end

    it "increases the maximum capacity" do
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

  describe "#<<" do
    it "adds items to the buffer" do
      buffer = Bugsnag::Utility::CircularBuffer.new
      buffer << 1
      expect(buffer.to_a).to eq([1])
    end

    it "shifts items it #max_items is exceeded" do
      buffer = Bugsnag::Utility::CircularBuffer.new(5)
      (0...10).each { |x| buffer << x }

      expect(buffer.to_a).to eq([5, 6, 7, 8, 9])
    end

    it "can be chained" do
      buffer = Bugsnag::Utility::CircularBuffer.new
      buffer << 1 << 2 << 3 << 4 << 5

      expect(buffer.to_a).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "#each" do
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
  end
end