Feature: App version

Scenario Outline: App_version is nil by default
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.version" equals null

Scenario Outline: Setting app_version in initializer works
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_APP_VERSION" to "1.0.0"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.version" equals "1.0.0"

Scenario Outline: Setting app_version after initializer works
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=app_version&value=1.1.0" on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.version" equals "1.1.0"