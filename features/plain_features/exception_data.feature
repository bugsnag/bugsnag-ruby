Feature: Plain exception data

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An error has built in meta-data
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_meta_data.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "CustomError"
  And the event "metaData.exception.exception_type" equals "FATAL"
  And the event "metaData.exception.exception_base" equals "RuntimeError"

  Examples:
  | ruby version | state     |
  | 1.9.3        | unhandled |
  | 1.9.3        | handled   |
  | 2.0          | unhandled |
  | 2.0          | handled   |
  | 2.1          | unhandled |
  | 2.1          | handled   |
  | 2.2          | unhandled |
  | 2.2          | handled   |
  | 2.3          | unhandled |
  | 2.3          | handled   |
  | 2.4          | unhandled |
  | 2.4          | handled   |
  | 2.5          | unhandled |
  | 2.5          | handled   |

Scenario Outline: An error has built in context
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_context.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "CustomError"
  And the event "context" equals "IntegrationTests"

  Examples:
  | ruby version | state     |
  | 1.9.3        | unhandled |
  | 1.9.3        | handled   |
  | 2.0          | unhandled |
  | 2.0          | handled   |
  | 2.1          | unhandled |
  | 2.1          | handled   |
  | 2.2          | unhandled |
  | 2.2          | handled   |
  | 2.3          | unhandled |
  | 2.3          | handled   |
  | 2.4          | unhandled |
  | 2.4          | handled   |
  | 2.5          | unhandled |
  | 2.5          | handled   |

Scenario Outline: An error has built in grouping hash
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_hash.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "CustomError"
  And the event "groupingHash" equals "ABCDE12345"

  Examples:
  | ruby version | state     |
  | 1.9.3        | unhandled |
  | 1.9.3        | handled   |
  | 2.0          | unhandled |
  | 2.0          | handled   |
  | 2.1          | unhandled |
  | 2.1          | handled   |
  | 2.2          | unhandled |
  | 2.2          | handled   |
  | 2.3          | unhandled |
  | 2.3          | handled   |
  | 2.4          | unhandled |
  | 2.4          | handled   |
  | 2.5          | unhandled |
  | 2.5          | handled   |

Scenario Outline: An error has built in user id
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby exception_data/<state>_user_id.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the exception "errorClass" equals "CustomError"
  And the event "user.id" equals "000001"

  Examples:
  | ruby version | state     |
  | 1.9.3        | unhandled |
  | 1.9.3        | handled   |
  | 2.0          | unhandled |
  | 2.0          | handled   |
  | 2.1          | unhandled |
  | 2.1          | handled   |
  | 2.2          | unhandled |
  | 2.2          | handled   |
  | 2.3          | unhandled |
  | 2.3          | handled   |
  | 2.4          | unhandled |
  | 2.4          | handled   |
  | 2.5          | unhandled |
  | 2.5          | handled   |