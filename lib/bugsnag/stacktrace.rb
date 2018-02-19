module Bugsnag
  class Stacktrace

    # e.g. "org/jruby/RubyKernel.java:1264:in `catch'"
    BACKTRACE_LINE_REGEX = /^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$/

    # e.g. "org.jruby.Ruby.runScript(Ruby.java:807)"
    JAVA_BACKTRACE_REGEX = /^(.*)\((.*)(?::([0-9]+))?\)$/

    # Path to vendored code. Used to mark file paths as out of project.
    VENDOR_PATH = /^(vendor\/|\.bundle\/)/

    ##
    # Process a backtrace and the configuration into a parsed stacktrace.
    def initialize(backtrace, configuration)
      @configuration = configuration

      backtrace = caller if !backtrace || backtrace.empty?
      @processed_backtrace = backtrace.map do |trace|
        if trace.match(BACKTRACE_LINE_REGEX)
          file, line_str, method = [$1, $2, $3]
        elsif trace.match(JAVA_BACKTRACE_REGEX)
          method, file, line_str = [$1, $2, $3]
        end

        # Parse the stacktrace line

        # Skip stacktrace lines inside lib/bugsnag
        next(nil) if file.nil? || file =~ %r{lib/bugsnag(/|\.rb)}

        # Expand relative paths
        p = Pathname.new(file)
        if p.relative?
          file = p.realpath.to_s rescue file
        end

        # Generate the stacktrace line hash
        trace_hash = {}
        trace_hash[:lineNumber] = line_str.to_i

        if configuration.send_code
          trace_hash[:code] = code(file, trace_hash[:lineNumber])
        end

        # Clean up the file path in the stacktrace
        if defined?(@configuration.project_root) && @configuration.project_root.to_s != ''
          trace_hash[:inProject] = true if file.start_with?(@configuration.project_root.to_s)
          file.sub!(/#{@configuration.project_root}\//, "")
          trace_hash.delete(:inProject) if file.match(VENDOR_PATH)
        end


        # Strip common gem path prefixes
        if defined?(Gem)
          file = Gem.path.inject(file) {|line, path| line.sub(/#{path}\//, "") }
        end

        trace_hash[:file] = file

        # Add a method if we have it
        trace_hash[:method] = method if method && (method =~ /^__bind/).nil?

        if trace_hash[:file] && !trace_hash[:file].empty?
          trace_hash
        else
          nil
        end
      end.compact
    end

    ##
    # Returns the processed backtrace
    def to_a
      @processed_backtrace
    end

    private

    def code(file, line_number, num_lines = 7)
      code_hash = {}

      from_line = [line_number - num_lines, 1].max

      # don't try and open '(irb)' or '-e'
      return unless File.exist?(file)

      # Populate code hash with line numbers and code lines
      File.open(file) do |f|
        current_line_number = 0
        f.each_line do |line|
          current_line_number += 1

          next if current_line_number < from_line

          code_hash[current_line_number] = line[0...200].rstrip

          break if code_hash.length >= ( num_lines * 1.5 ).ceil
        end
      end

      while code_hash.length > num_lines
        last_line = code_hash.keys.max
        first_line = code_hash.keys.min

        if (last_line - line_number) > (line_number - first_line)
          code_hash.delete(last_line)
        else
          code_hash.delete(first_line)
        end
      end

      code_hash
    rescue
      @configuration.warn("Error fetching code: #{$!.inspect}")
      nil
    end
  end
end
