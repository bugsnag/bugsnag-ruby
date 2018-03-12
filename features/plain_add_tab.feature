Feature: Plain add tab to metadata

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: Metadata can be added to a report using add_tab
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby report_modification/add_tab.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "metaData.additional_metadata.foo" is "foo"
  And the event "metaData.additional_metadata.bar.0" is "b"
  And the event "metaData.additional_metadata.bar.1" is "a"
  And the event "metaData.additional_metadata.bar.2" is "r"

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

Scenario Outline: Metadata can be added to an existing tab using add_tab
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby report_modification/add_tab_existing.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "metaData.additional_metadata.foo" is "foo"
  And the event "metaData.additional_metadata.bar.0" is "b"
  And the event "metaData.additional_metadata.bar.1" is "a"
  And the event "metaData.additional_metadata.bar.2" is "r"
  And the event "metaData.additional_metadata.foobar.first" is "foo"
  And the event "metaData.additional_metadata.foobar.then" is "bar"

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

Scenario Outline: Metadata can be overwritten using add_tab
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "CALLBACK_INITIATOR" to "<initiator>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby report_modification/add_tab_override.rb" on the service "features/fixtures/docker-compose.yml"
  And I wait for 1 second
  Then I should receive a request
  And the request used the Ruby notifier
  And the request used payload v4 headers
  And the request contained the api key "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the event "metaData.additional_metadata.foo" is "foo"
  And the event "metaData.additional_metadata.bar" is "bar"

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