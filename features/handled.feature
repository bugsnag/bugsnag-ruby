Feature: Handled error

  Handled errors can be sent from every supported framework. These errors should include framework specific metadata. We ensure we test a good distribution of ruby and framework versions.

Background:
  Given I configure the bugsnag endpoint

Scenario Outline: Handled RuntimeError
  Given I set environment variable "ruby_version" to "<ruby_version>"
  And I configure the bugsnag endpoint
  And I start the compose app "<compose_app>"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/handled"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
    | ruby_version | compose_app | port |
    |      2.0     |    rails3   | 3003 |
    |      2.5     |    rails3   | 3003 |
    |      2.0     |    rails4   | 3004 |
    |      2.5     |    rails4   | 3004 |
    |      2.2     |    rails5   | 3005 |
    |      2.5     |    rails5   | 3005 |

Scenario Outline: Manual string notify

  If a string is passed to Bugsnag.notify it should be coerced into a RuntimeError.

  Given I set environment variable "ruby_version" to "<ruby_version>"
  And I configure the bugsnag endpoint
  And I start the compose app "<compose_app>"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/string_notify"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
    | ruby_version | compose_app | port |
    |      2.0     |    rails3   | 3003 |
    |      2.5     |    rails3   | 3003 |
    |      2.0     |    rails4   | 3004 |
    |      2.5     |    rails4   | 3004 |
    |      2.2     |    rails5   | 3005 |
    |      2.5     |    rails5   | 3005 |
