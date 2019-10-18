Feature: Rails handled errors

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Unhandled RuntimeError
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/handled/unthrown" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "unhandled" is false
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled unthrown error"
  And the event "app.type" equals "rails"
  And the event "metaData.request.url" ends with "/handled/unthrown"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"

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

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Thrown handled NameError
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/handled/thrown" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the exception "errorClass" equals "NameError"
  And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<HandledController"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/handled/thrown"
  And the event "app.type" equals "rails"
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"

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

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Manual string notify
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/handled/string_notify" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "handled string"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/handled/string_notify"
  And the event "app.type" equals "rails"

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
