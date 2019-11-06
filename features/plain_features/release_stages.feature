Feature: Release stage configuration options

Scenario: Doesn't notify in the wrong release stage
  Given I set environment variable "BUGSNAG_NOTIFY_RELEASE_STAGE" to "stage_one"
  And I set environment variable "BUGSNAG_RELEASE_STAGE" to "stage_two"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_unhandled.rb"
  And I wait for 1 second
  Then I should receive no requests

Scenario: Does notify in the correct release stage
  Given I set environment variable "BUGSNAG_NOTIFY_RELEASE_STAGE" to "stage_one"
  And I set environment variable "BUGSNAG_RELEASE_STAGE" to "stage_one"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_unhandled.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "unhandled" is true
  And the event "severity" equals "error"
  And the event "severityReason.type" equals "unhandledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "/usr/src/app/configuration/send_unhandled.rb"
