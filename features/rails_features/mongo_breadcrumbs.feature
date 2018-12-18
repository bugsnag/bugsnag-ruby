Feature: Mongo automatic breadcrumbs

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint


Scenario Outline: Failure breadcrumbs
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/mongo/failure_crash" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event has a "process" breadcrumb named "Mongo query started"
  And the event has a "process" breadcrumb named "Mongo query failed"

  Examples:
    | ruby_version | rails_version |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 5             |
    | 2.5          | 5             |