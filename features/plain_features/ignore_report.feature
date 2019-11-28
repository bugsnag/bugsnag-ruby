Feature: Plain ignore report

Scenario Outline: A reports severity can be modified
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/ignore_report.rb"
  And I wait for 1 second
  Then I should receive no requests

  Examples:
  | initiator               |
  | handled_before_notify   |
  | unhandled_before_notify |
