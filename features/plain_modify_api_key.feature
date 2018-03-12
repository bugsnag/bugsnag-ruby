Feature: Plain report modify api key

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: A report can have its api_key modified
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby report_modification/modify_api_key.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "abcdefghijklmnopqrstuvwxyz123456"

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