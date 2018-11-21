Feature: Release stage configuration options

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: Doesn't notify in the wrong release stage
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "BUGSNAG_NOTIFY_RELEASE_STAGE" to "stage_one"
  And I set environment variable "BUGSNAG_RELEASE_STAGE" to "stage_two"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_unhandled.rb"
  And I wait for 1 second
  Then I should receive 0 requests

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: Doesn't notify in the wrong release stage
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "BUGSNAG_NOTIFY_RELEASE_STAGE" to "stage_one"
  And I set environment variable "BUGSNAG_RELEASE_STAGE" to "stage_one"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_unhandled.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/app/configuration/send_unhandled.rb"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |