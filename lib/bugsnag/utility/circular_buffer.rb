module Bugsnag::Utility
  class CircularBuffer
    include Enumerable

    attr_reader :max_items

    def initialize(max_items=25)
      @max_items = max_items
      @buffer = []
    end

    def <<(item)
      @buffer << item
      trim_buffer
      self
    end

    def each(&block)
      @buffer.each(&block)
    end

    def max_items=(new_max_items)
      @max_items = new_max_items
      trim_buffer
    end

    private
    def trim_buffer
      trim_size = @buffer.size - @max_items
      trim_size = 0 if trim_size < 0
      @buffer.shift(trim_size)
    end
  end
end