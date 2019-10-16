Feature: delivery_method configuration option

Scenario: When the delivery_method is set to :synchronous
  When I run the service "plain-ruby" with the command "bundle exec ruby delivery/synchronous.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_synchronous.json"

Scenario: When the delivery_method is set to :thread_queue
  When I run the service "plain-ruby" with the command "bundle exec ruby delivery/threadpool.rb"
  And I wait to receive a request
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_threadpool.json"


Scenario: When the delivery_method is set to :thread_queue in a fork
  When I run the service "plain-ruby" with the command "bundle exec ruby delivery/fork_threadpool.rb"
  And I wait to receive 2 requests
  Then the request is valid for the error reporting API version "4.0" for the "Ruby Bugsnag Notifier"
  And the exception "errorClass" equals "RuntimeError"
  And the event "metaData.config" matches the JSON fixture in "features/fixtures/plain/json/delivery_fork.json"
