Feature: proxy configuration options

@wip
Scenario: Proxy settings are provided as configuration options
  When I set environment variable "BUGSNAG_PROXY_HOST" to "http://proxy"
  And I set environment variable "BUGSNAG_PROXY_PORT" to "3128"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

@wip
Scenario: Proxy settings are provided as the HTTP_PROXY environment variable
  Given I set environment variable "HTTP_PROXY" to "http://proxy:3128"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

@wip
Scenario: Proxy settings are provided as the HTTPS_PROXY environment variable
  Given I set environment variable "HTTPS_PROXY" to "https://proxy:3128"
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"
