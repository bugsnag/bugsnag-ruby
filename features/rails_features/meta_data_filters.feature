Feature: Metadata filters

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Meta_data_filters should include Rails.configuration.filter_parameters
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/metadata_filters/filter" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "unhandled" is false
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/metadata_filters/filter"
  And the event "metaData.my_specific_filter" equals "[FILTERED]"


  Examples:
    | ruby_version | rails_version |
    | 2.0          | 3             |
    | 2.1          | 3             |
    | 2.2          | 3             |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 3             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 3             |
    | 2.4          | 5             |
    | 2.5          | 3             |
    | 2.5          | 5             |
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |
