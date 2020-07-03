module Bugsnag
  class Stacktrace

    # e.g. "org/jruby/RubyKernel.java:1264:in `catch'"
    BACKTRACE_LINE_REGEX = /^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$/

    # e.g. "org.jruby.Ruby.runScript(Ruby.java:807)"
    JAVA_BACKTRACE_REGEX = /^(.*)\((.*)(?::([0-9]+))?\)$/

    ##
    # Process a backtrace and the configuration into a parsed stacktrace.
    #
    # rubocop:todo Metrics/CyclomaticComplexity
    def initialize(backtrace, configuration)
      @configuration = configuration

      if configuration.send_code
        require_relative 'code_extractor'
        code_extractor = CodeExtractor.new
      end

      backtrace = caller if !backtrace || backtrace.empty?

      @processed_backtrace = backtrace.map do |trace|
        # Parse the stacktrace line
        if trace.match(BACKTRACE_LINE_REGEX)
          file, line_str, method = [$1, $2, $3]
        elsif trace.match(JAVA_BACKTRACE_REGEX)
          method, file, line_str = [$1, $2, $3]
        end

        next(nil) if file.nil?

        # Expand relative paths
        file = File.realpath(file) rescue file

        # Generate the stacktrace line hash
        trace_hash = { lineNumber: line_str.to_i }

        # Save a copy of the file path as we're about to modify it but need the
        # raw version when extracting code (otherwise we can't open the file)
        # TODO we need a test to cover this (or it may be unnecessary!)
        raw_file_path = file

        # Clean up the file path in the stacktrace
        if defined?(@configuration.project_root) && @configuration.project_root.to_s != ''
          trace_hash[:inProject] = true if file.start_with?(@configuration.project_root.to_s)
          file.sub!(/#{@configuration.project_root}\//, "")
          trace_hash.delete(:inProject) if file.match(@configuration.vendor_path)
        end

        # Strip common gem path prefixes
        if defined?(Gem)
          file = Gem.path.inject(file) {|line, path| line.sub(/#{path}\//, "") }
        end

        trace_hash[:file] = file

        # Add a method if we have it
        trace_hash[:method] = method if method && (method =~ /^__bind/).nil?

        if trace_hash[:file] && !trace_hash[:file].empty?
          # If we're going to send code then record the raw file path and the
          # trace_hash, so we can extract from it later
          code_extractor.add_file(raw_file_path, trace_hash) if configuration.send_code

          trace_hash
        else
          nil
        end
      end.compact

      code_extractor.extract! if configuration.send_code
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    ##
    # Returns the processed backtrace
    def to_a
      @processed_backtrace
    end
  end
end
