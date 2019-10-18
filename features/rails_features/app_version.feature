Feature: App version configuration

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3 @rails4 @rails5 @rails6
Scenario Outline: App_version is nil by default
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/app_version/default" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.version" is null

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
Scenario Outline: Setting app_version in initializer works
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "BUGSNAG_APP_VERSION" to "1.0.0"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/app_version/initializer" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "app.version" equals "1.0.0"

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
Scenario Outline: Setting app_version after initializer works
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/app_version/after?version=1.1.0" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the event "app.version" equals "1.1.0"

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