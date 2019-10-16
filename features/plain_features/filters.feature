Feature: Plain filtering of metadata

Scenario: Metadata is filtered through the default filters
  When I run the service "plain-ruby" with the command "bundle exec ruby filters/default_filters.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "metaData.filter" matches the JSON fixture in "features/fixtures/plain/json/filters_default_metadata_filters.json"

Scenario: Additional filters can be added to the filter list
  Given I set environment variable "BUGSNAG_META_DATA_FILTERS" to "filter_me"
  When I run the service "plain-ruby" with the command "bundle exec ruby filters/additional_filters.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "metaData.filter.filter_me" equals "[FILTERED]"
