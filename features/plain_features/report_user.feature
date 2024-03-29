Feature: Plain report modify user

Scenario Outline: A report can have a user name, email, and id set
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/set_user_details.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user.name" equals "leo testman"
  And the event "user.email" equals "test@test.com"
  And the event "user.id" equals "0001"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |

Scenario Outline: A report can have custom info set
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I run the service "plain-ruby" with the command "bundle exec ruby report_modification/set_custom_user_details.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user.type" equals "amateur"
  And the event "user.location" equals "testville"
  And the event "user.details.a" equals "foo"
  And the event "user.details.b" equals "bar"

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |

Scenario Outline: A report can have its user info removed
  Given I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  When I run the service "plain-ruby" with the command "bundle exec ruby report_modification/remove_user_details.rb"
  And I wait to receive an error
  Then the error is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier" notifier
  And the event "user" is null

  Examples:
  | initiator               |
  | handled_before_notify   |
  | handled_block           |
  | unhandled_before_notify |
  | handled_on_error        |
  | unhandled_on_error      |
