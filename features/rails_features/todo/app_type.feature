Feature: App type

# Scenario Outline: Setting app_type in initializer works
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_APP_TYPE" to "maze_env"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
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
  And the event "app.type" equals "maze_env"

# Scenario Outline: Changing app_type after initializer works
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=app_type&value=maze_after_initializer" on port "<port>"
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
  And the event "app.type" equals "maze_after_initializer"