module Bugsnag::Middleware
  ##
  # Attaches any "Did you mean?" suggestions to the report
  class SuggestionData

    CAPTURE_REGEX = /Did you mean\?([\s\S]+)$/
    DELIMITER = "\n"

    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(event)
      matches = []

      event.errors.each do |error|
        match = CAPTURE_REGEX.match(error.error_message)

        next unless match

        suggestions = match.captures[0].split(DELIMITER)
        matches.concat(suggestions.map(&:strip))
      end

      if matches.size == 1
        event.add_metadata(:error, { suggestion: matches.first })
      elsif matches.size > 1
        event.add_metadata(:error, { suggestions: matches })
      end

      @bugsnag.call(event)
    end
  end
end
