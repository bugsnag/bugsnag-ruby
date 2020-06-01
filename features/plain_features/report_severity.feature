Feature: Plain report modify severity

Scenario Outline: A reports severity can be modified
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/modify_severity.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "severity" equals "info"
  And the event "severityReason.type" equals "userCallbackSetSeverity"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
