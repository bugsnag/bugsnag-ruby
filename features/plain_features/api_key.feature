Feature: API Key configuration options

Background:
  And I set environment variable "APP_PATH" to "/usr/src"
  And I configure the bugsnag endpoint

Scenario Outline: The API key configuration option can be set
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "BUGSNAG_API_KEY" to "b35a2a72bd230ac0aa0f52715bbdc6aa"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/api_key.rb"
  And I wait for 1 second
  Then I should receive a request
  And the request used the "Ruby Bugsnag Notifier" notifier
  And the request used payload v4 headers
  And the request contained the api key "b35a2a72bd230ac0aa0f52715bbdc6aa"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |