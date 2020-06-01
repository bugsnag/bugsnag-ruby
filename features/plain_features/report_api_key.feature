Feature: Plain report modify api key

Scenario Outline: A report can have its api_key modified
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/modify_api_key.rb"
  And I wait to receive a request
  Then the "Bugsnag-Api-Key" header equals "abcdefghijklmnopqrstuvwxyz123456"
  And the payload field "apiKey" equals "abcdefghijklmnopqrstuvwxyz123456"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |