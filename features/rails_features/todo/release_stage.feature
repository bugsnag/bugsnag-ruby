Feature: Release stage

Scenario Outline: Release_stage should default to RAILS_ENV
  Given I set environment variable "RAILS_ENV" to "maze_rails_env"
  And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.releaseStage" equals "maze_rails_env"

Scenario Outline: Release_stage can be set in an initializer
  Given I set environment variable "MAZE_RELEASE_STAGE" to "maze_release_stage_env"
  And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.releaseStage" equals "maze_release_stage_env"

Scenario Outline: Release_stage can be set after an initializer
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  When I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=release_stage&value=maze_release_stage_param" on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the request is a valid for the error reporting API
  And the payload field "events" is an array with 1 element
  And the event "app.releaseStage" equals "maze_release_stage_param"
