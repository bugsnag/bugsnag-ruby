module Bugsnag::Middleware
  class SuggestionData

    CAPTURE_REGEX = /Did you mean\?([\s\S]+)$/
    DELIMITER = "\n"

    ##
    # Attaches any "Did you mean?" style suggestion data to the report.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      matches = []
      report.raw_exceptions.each do |exception|
        match = CAPTURE_REGEX.match(exception.message)
        next unless match

        suggestions = match.captures[0].split(DELIMITER)
        matches.concat suggestions.map{ |suggestion| suggestion.strip }
      end

      if matches.size == 1
        report.add_tab(:error, {:suggestion => matches.first})
      elsif matches.size > 1
        report.add_tab(:error, {:suggestions => matches})
      end

      @bugsnag.call(report)
    end
  end
end
