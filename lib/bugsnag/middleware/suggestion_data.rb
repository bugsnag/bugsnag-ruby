module Bugsnag::Middleware
  class SuggestionData

    CAPTURE_REGEX = /Did you mean\?([\s\S]+)$/
    DELIMITER = "\n"

    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    def call(report)
      matches = {}
      report.raw_exceptions.each do |exception| 
        match = CAPTURE_REGEX.match(exception.message)
        next unless match
        
        suggestions = match.captures[0].split(DELIMITER).each { |suggestion|
          matches[matches.size] = suggestion.strip
        }
      end

      report.add_tab(:suggestion, matches) if matches.size > 0
      
      @bugsnag.call(report)
    end
  end
end
