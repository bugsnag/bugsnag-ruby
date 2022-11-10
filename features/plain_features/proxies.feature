Feature: proxy configuration options

Scenario: Proxy settings are provided as configuration options
  Given I configure the BUGSNAG_PROXY environment variables
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

Scenario: Proxy settings are provided as the HTTP_PROXY environment variable
  Given I configure the http_proxy environment variable
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"

Scenario: Proxy settings are provided as the HTTPS_PROXY environment variable
  Given I configure the https_proxy environment variable
  When I run the service "plain-ruby" with the command "bundle exec ruby configuration/proxy.rb"
  Then I wait to receive a request
  And the "proxy-authorization" header equals "Basic dGVzdGVyOnRlc3RwYXNz"
  And the event "metaData.proxy.user" equals "tester"
