Feature: Auto capture sessions

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: 100 session calls results in 100 sessions
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/session_tracking/hundred" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the session tracking API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the sessionCount "startedAt" is a timestamp
  And the sessionCount "sessionsStarted" equals 100

  Examples:
    | ruby_version | rails_version |
    | 2.0          | 3             |
    | 2.1          | 3             |
    | 2.2          | 3             |
    | 2.2          | 4             |
    | 2.2          | 5             |
    | 2.3          | 3             |
    | 2.3          | 4             |
    | 2.3          | 5             |
    | 2.4          | 3             |
    | 2.4          | 5             |
    | 2.5          | 3             |
    | 2.5          | 5             |