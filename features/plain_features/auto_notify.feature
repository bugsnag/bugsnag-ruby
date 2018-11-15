Feature: Auto notify configuration option

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: When Auto-notify is false notifications are not sent
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "BUGSNAG_AUTO_NOTIFY" to "false"
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