Feature: Plain handled errors

Scenario: A rescued exception sends a report
  When I run the service "plain-ruby" with the command "bundle exec ruby handled/notify_exception.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "device.time" is a timestamp
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "handled/notify_exception.rb"
  And the "lineNumber" of stack frame 0 equals 6

Scenario: A notified string sends a report
  When I run the service "plain-ruby" with the command "bundle exec ruby handled/notify_string.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the event "device.time" is a timestamp
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of the top non-bugsnag stackframe equals "handled/notify_string.rb"
  And the "lineNumber" of the top non-bugsnag stackframe equals 8

Scenario: A handled error doesn't send a report when the :skip_bugsnag flag is set
  When I run the service "plain-ruby" with the command "bundle exec ruby handled/ignore_exception.rb"
  Then I should receive no requests

Scenario: A handled error can attach metadata in a block
  When I run the service "plain-ruby" with the command "bundle exec ruby handled/block_metadata.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "unhandled" is false
  And the event "severity" equals "warning"
  And the event "severityReason.type" equals "handledException"
  And the exception "errorClass" equals "RuntimeError"
  And the "file" of stack frame 0 equals "handled/block_metadata.rb"
  And the "lineNumber" of stack frame 0 equals 6
  And the event "metaData.account.id" equals "1234abcd"
  And the event "metaData.account.name" equals "Acme Co"
  And the event "metaData.account.support" is true
  And the event "device.time" is a timestamp
