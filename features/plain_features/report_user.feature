Feature: Plain report modify user

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: A report can have a user name, email, and id set
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby report_modification/set_user_details.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "user.name" is "leo testman"
  And the event "user.email" is "test@test.com"
  And the event "user.id" is "0001"

  Examples:
  | ruby version | initiator               |
  | 1.9.3        | handled_before_notify   |
  | 1.9.3        | handled_block           |
  | 1.9.3        | unhandled_before_notify |
  | 2.0          | handled_before_notify   |
  | 2.0          | handled_block           |
  | 2.0          | unhandled_before_notify |
  | 2.1          | handled_before_notify   |
  | 2.1          | handled_block           |
  | 2.1          | unhandled_before_notify |
  | 2.2          | handled_before_notify   |
  | 2.2          | handled_block           |
  | 2.2          | unhandled_before_notify |
  | 2.3          | handled_before_notify   |
  | 2.3          | handled_block           |
  | 2.3          | unhandled_before_notify |
  | 2.4          | handled_before_notify   |
  | 2.4          | handled_block           |
  | 2.4          | unhandled_before_notify |
  | 2.5          | handled_before_notify   |
  | 2.5          | handled_block           |
  | 2.5          | unhandled_before_notify |

Scenario Outline: A report can have custom info set
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby report_modification/set_custom_user_details.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "user.type" is "amateur"
  And the event "user.location" is "testville"
  And the event "user.details.a" is "foo"
  And the event "user.details.b" is "bar"

  Examples:
  | ruby version | initiator               |
  | 1.9.3        | handled_before_notify   |
  | 1.9.3        | handled_block           |
  | 1.9.3        | unhandled_before_notify |
  | 2.0          | handled_before_notify   |
  | 2.0          | handled_block           |
  | 2.0          | unhandled_before_notify |
  | 2.1          | handled_before_notify   |
  | 2.1          | handled_block           |
  | 2.1          | unhandled_before_notify |
  | 2.2          | handled_before_notify   |
  | 2.2          | handled_block           |
  | 2.2          | unhandled_before_notify |
  | 2.3          | handled_before_notify   |
  | 2.3          | handled_block           |
  | 2.3          | unhandled_before_notify |
  | 2.4          | handled_before_notify   |
  | 2.4          | handled_block           |
  | 2.4          | unhandled_before_notify |
  | 2.5          | handled_before_notify   |
  | 2.5          | handled_block           |
  | 2.5          | unhandled_before_notify |

Scenario Outline: A report can have its user info removed
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby report_modification/remove_user_details.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "user" is null

  Examples:
  | ruby version | initiator               |
  | 1.9.3        | handled_before_notify   |
  | 1.9.3        | handled_block           |
  | 1.9.3        | unhandled_before_notify |
  | 2.0          | handled_before_notify   |
  | 2.0          | handled_block           |
  | 2.0          | unhandled_before_notify |
  | 2.1          | handled_before_notify   |
  | 2.1          | handled_block           |
  | 2.1          | unhandled_before_notify |
  | 2.2          | handled_before_notify   |
  | 2.2          | handled_block           |
  | 2.2          | unhandled_before_notify |
  | 2.3          | handled_before_notify   |
  | 2.3          | handled_block           |
  | 2.3          | unhandled_before_notify |
  | 2.4          | handled_before_notify   |
  | 2.4          | handled_block           |
  | 2.4          | unhandled_before_notify |
  | 2.5          | handled_before_notify   |
  | 2.5          | handled_block           |
  | 2.5          | unhandled_before_notify |