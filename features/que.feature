Feature: Errors are delivered to Bugsnag from Que

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: Que will deliver unhandled errors
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "que"
  And I run the service "que" with the command "bundle exec ruby app.rb unhandled"
  And I run the service "que" with the command "bundle exec que ./app.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledExceptionMiddleware"
  And the event "severityReason.attributes.framework" equals "Que"
  And the event "app.type" equals "que"
  And the exception "errorClass" equals "RuntimeError"

  Examples:
  | ruby version |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: Que will deliver handled errors
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "que"
  And I run the service "que" with the command "bundle exec ruby app.rb handled"
  And I run the service "que" with the command "bundle exec que ./app.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "app.type" equals "que"
  And the exception "errorClass" equals "RuntimeError"

  Examples:
  | ruby version |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |