# Feature: Rails 3 support
#
# Background:
#   Given I set environment variable "ruby_version" to "2.4"
#   And I configure the bugsnag endpoint
#   And I start the compose app "rails3"
#   And I wait for the app to respond on port "3003"
#
# Scenario: Unhandled exception
#   When I navigate to the route "/unhandled"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
