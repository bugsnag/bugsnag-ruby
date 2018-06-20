Feature: Plain filtering of metadata

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: Metadata is filtered through the default filters
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby filters/default_filters.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "metaData.filter" matches the JSON fixture in "features/fixtures/plain/json/filters_default_metadata_filters.json"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: Additional filters can be added to the filter list
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "MAZE_META_DATA_FILTERS" to "filter_me"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby filters/additional_filters.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "metaData.filter.filter_me" is "[FILTERED]"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |