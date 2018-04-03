Feature: Send environment

## send_environment
#TODO:SM Need to verify not normally sent
Scenario Outline: Send_environment should send environment in handled errors when true
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=send_environment&value=true" on port "<port>"
  And I navigate to the route "/unthrown_handled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the exception "errorClass" equals "RuntimeError"
  And the exception "message" starts with "unthrown handled error"
  And the event "unhandled" is false
  And the event "metaData.request.url" ends with "/unthrown_handled"
  And the event "metaData.environment.REQUEST_METHOD" equals "GET"
  And the event "app.type" equals "rails"

Scenario Outline: Send_environment should send environment in unhandled errors when true
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=send_environment&value=true" on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the request used the Ruby notifier
  And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And the payload field "events" is an array with 1 element
  And the exception "errorClass" equals "NameError"
  And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
  And the event "unhandled" is true
  And the event "metaData.request.url" ends with "/unhandled"
  And the event "metaData.environment.REQUEST_METHOD" equals "GET"
  And the event "app.type" equals "rails"