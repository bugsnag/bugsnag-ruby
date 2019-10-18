Feature: Auto capture sessions

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Auto_capture_sessions defaults to true
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "USE_DEFAULT_AUTO_CAPTURE_SESSIONS" to "true"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/session_tracking/initializer" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the session tracking API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the sessionCount "startedAt" is a timestamp

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
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Auto_capture_sessions can be set to false in the initializer
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/session_tracking/initializer" on port "6128<rails_version>"
  Then I should receive 0 requests

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
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails3 @rails4 @rails5 @rails6
Scenario Outline: Manual sessions are still sent if Auto_capture_sessions is false
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/session_tracking/manual" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the session tracking API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the sessionCount "startedAt" is a timestamp

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
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |

@rails3 @rails4 @rails5 @rails6
Scenario Outline: 100 session calls results in 100 sessions
  Given I set environment variable "RUBY_VERSION" to "<ruby_version>"
  And I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the service "rails<rails_version>"
  And I wait for the app to respond on port "6128<rails_version>"
  When I navigate to the route "/session_tracking/multi_sessions" on port "6128<rails_version>"
  Then I should receive a request
  And the request is a valid for the session tracking API
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the sessionCount "startedAt" is a timestamp
  And the total sessionStarted count equals 100

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
    | 2.5          | 6             |
    | 2.6          | 5             |
    | 2.6          | 6             |