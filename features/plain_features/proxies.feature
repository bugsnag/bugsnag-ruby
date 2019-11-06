Feature: proxy configuration options

Scenario: Proxy settings are provided as configuration options
  When I set environment variable "BUGSNAG_PROXY_HOST" to "maze-runner"
  And I set environment variable "BUGSNAG_PROXY_PORT" to "9339"
  And I set environment variable "BUGSNAG_PROXY_USER" to "tester"
  And I set environment variable "BUGSNAG_PROXY_PASSWORD" to "testpass"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

Scenario: Proxy settings are provided as the HTTP_PROXY environment variable
  Given I set environment variable "http_proxy" to "http://tester:testpass@maze-runner:9339"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

Scenario: Proxy settings are provided as the HTTPS_PROXY environment variable
  Given I set environment variable "https_proxy" to "http://tester:testpass@maze-runner:9339"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"
