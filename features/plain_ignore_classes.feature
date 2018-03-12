Feature: Plain ignore classes

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: An errors class is in the ignore_classes array
  And I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I build the service "plain-ruby" from the compose file "features/fixtures/plain/docker-compose.yml"
  And I run the command "plain-ruby bundle exec ruby ignore_classes/<state>.rb" on the service "features/fixtures/plain/docker-compose.yml"
  And I wait for 1 second
  Then I should receive 0 requests

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