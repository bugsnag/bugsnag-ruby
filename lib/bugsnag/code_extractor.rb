module Bugsnag
  class CodeExtractor
    NUMBER_OF_LINES_TO_FETCH = 11
    HALF_NUMBER_OF_LINES_TO_FETCH = (NUMBER_OF_LINES_TO_FETCH / 2).ceil + 1
    MAXIMUM_LINES_TO_KEEP = 7

    def initialize
      @files = {}
    end

    ##
    # @param [String] path
    # @param [Hash] trace
    # @return [void]
    def add_file(path, trace)
      # If the file doesn't exist we don't care about it. For BC with the old
      # method of extraction, set :code to nil
      # TODO is this necessary? I don't think the API cares if code is 'null' or
      #      missing entirely in the JSON as code sending is optional
      unless File.exist?(path)
        trace[:code] = nil

        return
      end

      @files[path] ||= []
      @files[path].push(trace)

      # Record the line numbers we want to fetch for this trace
      first_line_number = trace[:lineNumber] - HALF_NUMBER_OF_LINES_TO_FETCH

      trace[:first_line_number] = first_line_number < 1 ? 1 : first_line_number
      trace[:last_line_number] = trace[:lineNumber] + HALF_NUMBER_OF_LINES_TO_FETCH
    end

    ##
    # Add the code to the hashes that were given in #add_file
    #
    # TODO the old method has a rescue around the entire extraction process
    #      is this needed (presumably is)? Can we add tests that raise?
    #      We will need to handle exceptions differently in each stage; e.g.
    #      if we fail while reading the file then every trace that needs that
    #      file will not have code attached. However if we fail while attaching
    #      the code to a trace, we can skip to the next trace and try that one
    #      (though I don't know why we would fail anywhere other than File IO)
    #
    # @return [void]
    def extract!
      @files.each do |path, traces|
        line_numbers = Set.new

        traces.each do |trace|
          trace[:first_line_number].upto(trace[:last_line_number]) do |line_number|
            line_numbers << line_number
          end
        end

        extract_from(path, traces, line_numbers)
      end
    end

    private

    def extract_from(path, traces, line_numbers)
      code = {}

      File.open(path) do |file|
        current_line_number = 0

        file.each_line do |line|
          current_line_number += 1

          next unless line_numbers.include?(current_line_number)

          # TODO test for 200 character limit
          code[current_line_number] = line[0...200].rstrip
        end
      end

      associate_code_with_trace(code, traces)
    end

    def associate_code_with_trace(code, traces)
      traces.each do |trace|
        trace[:code] = {}

        code.each do |line_number, line|
          # If we've gone past the last line we care about we can stop iteration
          break if line_number > trace[:last_line_number]

          # Skip lines that aren't in the range we want
          next unless line_number >= trace[:first_line_number]

          trace[:code][line_number] = line
        end

        trim_excess_lines(trace[:code], trace[:lineNumber])
        trace.delete(:first_line_number)
        trace.delete(:last_line_number)
      end
    end

    def trim_excess_lines(code, line_number)
      while code.length > MAXIMUM_LINES_TO_KEEP
        last_line = code.keys.max
        first_line = code.keys.min

        if (last_line - line_number) > (line_number - first_line)
          code.delete(last_line)
        else
          code.delete(first_line)
        end
      end
    end
  end
end
