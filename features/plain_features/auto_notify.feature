Feature: Auto notify configuration option

Scenario: When Auto-notify is false notifications are not sent
  Given I set environment variable "BUGSNAG_AUTO_NOTIFY" to "false"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/send_unhandled.rb"
  And I wait for 1 second
  Then I should receive no requests
