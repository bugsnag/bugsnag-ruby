Feature: proxy configuration options

Background:
  Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I configure the bugsnag endpoint

Scenario Outline: Proxy settings are provided as configuration options
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "BUGSNAG_PROXY_HOST" to the current IP
  And I set environment variable "BUGSNAG_PROXY_PORT" to the mock API port
  And I set environment variable "BUGSNAG_PROXY_USER" to "tester"
  And I set environment variable "BUGSNAG_PROXY_PASSWORD" to "testpass"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  And I wait for 1 second
  Then I should receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: Proxy settings are provided as the HTTP_PROXY environment variable
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "http_proxy" to the proxy settings with credentials "http://tester:testpass"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  And I wait for 1 second
  Then I should receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |

Scenario Outline: Proxy settings are provided as the HTTPS_PROXY environment variable
  Given I set environment variable "RUBY_VERSION" to "<ruby version>"
  And I set environment variable "https_proxy" to the proxy settings with credentials "https://tester:testpass"
  And I have built the service "plain-ruby"
  And I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  And I wait for 1 second
  Then I should receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

  Examples:
  | ruby version |
  | 1.9.3        |
  | 2.0          |
  | 2.1          |
  | 2.2          |
  | 2.3          |
  | 2.4          |
  | 2.5          |
