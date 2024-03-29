Feature: Plain report modify severity

Scenario Outline: A reports severity can be modified
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/modify_severity.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "severity" equals "info"
  And the event "severityReason.type" equals "userCallbackSetSeverity"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |
