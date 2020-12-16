Feature: Auto capture sessions

@rails3 @rails4 @rails5 @rails6
Scenario: Auto_capture_sessions defaults to true
  Given I set environment variable "USE_DEFAULT_AUTO_CAPTURE_SESSIONS" to "true"
  And I start the rails service
  When I navigate to the route "/session_tracking/initializer" on the rails app
  And I wait to receive a request
  Then the request is valid for the session reporting API version "1.0" for the "Ruby Bugsnag Notifier" notifier

@rails3 @rails4 @rails5 @rails6
Scenario: Auto_capture_sessions can be set to false in the initializer
  Given I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the rails service
  When I navigate to the route "/session_tracking/initializer" on the rails app
  Then I should receive no requests

@rails3 @rails4 @rails5 @rails6
Scenario: Manual sessions are still sent if Auto_capture_sessions is false
  Given I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the rails service
  When I navigate to the route "/session_tracking/manual" on the rails app
  And I wait to receive a request
  Then the request is valid for the session reporting API version "1.0" for the "Ruby Bugsnag Notifier" notifier

@rails3 @rails4 @rails5 @rails6
Scenario: 100 session calls results in 100 sessions
  Given I set environment variable "BUGSNAG_AUTO_CAPTURE_SESSIONS" to "false"
  And I start the rails service
  When I navigate to the route "/session_tracking/multi_sessions" on the rails app
  And I wait to receive a request
  Then the request is valid for the session reporting API version "1.0" for the "Ruby Bugsnag Notifier" notifier
  And the total sessionStarted count equals 100
