Feature: Send code

Scenario Outline: Send_code should default to true
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the payload field "events" is an array with 1 element
  And the "code" of all stack frames is not null

Scenario Outline: Send_code can be updated in an initializer
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_SEND_CODE" to "false"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the payload field "events" is an array with 1 element
  And the "code" of all stack frames is null

Scenario Outline: Send_code can be updated after an initializer
  Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
  And I set environment variable "MAZE_SEND_CODE" to "false"
  And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
  And I wait for the app to respond on port "<port>"
  When I navigate to the route "/set_config_option?name=send_code&value=false" on port "<port>"
  And I navigate to the route "/unhandled" on port "<port>"
  Then I should receive a request
  And the payload field "events" is an array with 1 element
  And the "code" of all stack frames is null