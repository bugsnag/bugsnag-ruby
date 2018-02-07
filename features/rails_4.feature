Feature: Rails 4 support

Background:
  Given I configure the bugsnag endpoint

# Unhandled Errors
# Scenario Outline: Unandled RuntimeError
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the event "unhandled" is true
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "app.type" equals "rails"
#   And the event "metaData.request.url" ends with "/unhandled"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

# Handled Errors
# Scenario Outline: Unthrown handled RuntimeError
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unthrown_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the event "unhandled" is false
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "unthrown handled error"
#   And the event "app.type" equals "rails"
#   And the event "metaData.request.url" ends with "/unthrown_handled"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Thrown handled NameError
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/thrown_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "unhandled" is false
#   And the event "metaData.request.url" ends with "/thrown_handled"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Manual string notify
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/string_notify" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "handled string"
#   And the event "unhandled" is false
#   And the event "metaData.request.url" ends with "/string_notify"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

# Before notify callbacks
# Scenario Outline: Rails before_notify controller method works on handled errors
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/rails_before_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "handled string"
#   And the event "unhandled" is false
#   And the event "metaData.request.url" ends with "/rails_before_handled"
#   And the event "metaData.before_notify.source" equals "rails_before_handled"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Rails before_notify controller method works on unhandled errors
#   Given I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/rails_before_unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "unhandled" is true
#   And the event "metaData.request.url" ends with "/rails_before_unhandled"
#   And the event "metaData.before_notify.source" equals "rails_before_unhandled"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
Scenario Outline: Inline block on handled errors is called
Scenario Outline: Global callbacks called for handled errors
Scenario Outline: Global callbacks called for unhandled errors

# User information
Scenario Outline: Devise user information is sent on handled errors
Scenario Outline: Devise user information is sent on unhandled errors
Scenario Outline: Warden user information is sent on handled errors
Scenario Outline: Warden user information is sent on unhandled errors
Scenario Outline: Clearance user information is sent on handled errors
Scenario Outline: Clearance user information is sent on unhandled errors

# Session tracking
Scenario Outline: Manual session tracking sends session information
Scenario Outline: Session tracking information is included in unhandled errors for manual sessions
Scenario Outline: Session tracking information is included in handled errors for manual sessions
Scenario Outline: Session tracking information is included in unhandled errors for automatic sessions
Scenario Outline: Session tracking information is included in handled errors for automatic sessions

# Exception properties
Scenario Outline: Setting skip_bugsnag on exception wont auto_notify
Scenario Outline: Setting bugsnag_meta_data on exception is attached to a handled error
Scenario Outline: Setting bugsnag_meta_data on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_user_id on exception is attached to a handled error
Scenario Outline: Setting bugsnag_user_id on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_context on exception is attached to a handled error
Scenario Outline: Setting bugsnag_context on exception is attached to an unhandled error
Scenario Outline: Setting bugsnag_grouping_hash on exception is attached to a handled error
Scenario Outline: Setting bugsnag_grouping_hash on exception is attached to an unhandled error

## api_key
# Scenario Outline: Setting api_key in environment variable works
#   Given I set environment variable "BUGSNAG_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6a1"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6a1"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6a1"
#   And the payload field "events" is an array with 1 element
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
#
# Scenario Outline: Changing api_key after initializer works
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=api_key&value=a35a2a72bd230ac0aa0f52715bbdc6a2" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6a2"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6a2"
#   And the payload field "events" is an array with 1 element
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## app_type
# Scenario Outline: Setting app_type in initializer works
#   Given I set environment variable "MAZE_APP_TYPE" to "maze_env"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "unhandled" is true
#   And the event "metaData.request.url" ends with "/unhandled"
#   And the event "app.type" equals "maze_env"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Changing app_type after initializer works
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=app_type&value=maze_after_initializer" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "unhandled" is true
#   And the event "metaData.request.url" ends with "/unhandled"
#   And the event "app.type" equals "maze_after_initializer"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## app_version
# Scenario Outline: App_version is nil by default
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.version" equals null #TODO:SM Add this to maze
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
#
# Scenario Outline: Setting app_version in initializer works
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I set environment variable "MAZE_APP_VERSION" to "1.0.0"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.version" equals "1.0.0"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
#
# Scenario Outline: Setting app_version after initializer works
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=app_version&value=1.1.0" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.version" equals "1.1.0"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## auto_notify
# Scenario Outline: Auto_notify set to false in the initializer prevents unhandled error sending
#   Given I set environment variable "MAZE_AUTO_NOTIFY" to "false"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive 0 requests
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Auto_notify set to false in the initializer still sends handled errors
#   Given I set environment variable "MAZE_AUTO_NOTIFY" to "false"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unthrown_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the event "unhandled" is false
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "unthrown handled error"
#   And the event "app.type" equals "rails"
#   And the event "metaData.request.url" ends with "/unthrown_handled"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Auto_notify set to false after the initializer prevents unhandled error sending
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=auto_notify&value=false" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive 0 requests
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Auto_notify set to false after the initializer still sends handled errors
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=auto_notify&value=false" on port "<port>"
#   And I navigate to the route "/unthrown_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "unthrown handled error"
#   And the event "unhandled" is false
#   And the event "metaData.request.url" ends with "/unthrown_handled"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## auto_capture_sessions
Scenario Outline: Auto_capture_sessions is false by default
Scenario Outline: Auto_capture_sessions can be set to true in the initializer
Scenario Outline: Auto_capture_sessions can be set to true after the initializer

## meta_data_filters
Scenario Outline: Meta_data_filters should have sensible defaults from bugsnag
Scenario Outline: Meta_data_filters should include Rails.configuration.filter_parameters
Scenario Outline: Meta_data_filters should cope with strings
Scenario Outline: Meta_data_filters should cope with regular expressions

## notify_release_stages
Scenario Outline: Notify_release_stages should be nil by default
Scenario Outline: Notify_release_stages should block sending in that release stage
Scenario Outline: Notify_release_stages should allow sending in other release stages
Scenario Outline: Notify_release_stages should send in any release stage if its nil

## Ignore_classes
Scenario Outline: Ignore_classes is SystemExit and Interrupt by default
Scenario Outline: Ignore_classes can be set to a different value in initializer
Scenario Outline: Ignore_classes can be set to a different value after initializer
Scenario Outline: Ignore_classes can contain a class reference
Scenario Outline: Ignore_classes can contain a lambda

## project_root
Scenario Outline: Project_root should default to Rails.root
Scenario Outline: Project_root can be set in an initializer
Scenario Outline: Project_root can be set after an initializer

## proxy
Scenario Outline: Proxy_host should work
Scenario Outline: Http_proxy environment variable should work
Scenario Outline: Proxy_password should work
Scenario Outline: Proxy_port should work
Scenario Outline: Proxy_user should work

## release_stage
# Scenario Outline: Release_stage should default to RAILS_ENV
#   Given I set environment variable "RAILS_ENV" to "maze_rails_env"
#   And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.releaseStage" equals "maze_rails_env"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Release_stage can be set in an initializer
#   Given I set environment variable "MAZE_RELEASE_STAGE" to "maze_release_stage_env"
#   And I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.releaseStage" equals "maze_release_stage_env"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Release_stage can be set after an initializer
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   When I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=release_stage&value=maze_release_stage_param" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the payload field "events" is an array with 1 element
#   And the event "app.releaseStage" equals "maze_release_stage_param"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## send_code
# Scenario Outline: Send_code should default to true
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the payload field "events" is an array with 1 element
#   And the "code" of all stack frames is not null
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
#
# Scenario Outline: Send_code can be updated in an initializer
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I set environment variable "MAZE_SEND_CODE" to "false"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the payload field "events" is an array with 1 element
#   And the "code" of all stack frames is null
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
#
# Scenario Outline: Send_code can be updated after an initializer
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I set environment variable "MAZE_SEND_CODE" to "false"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=send_code&value=false" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the payload field "events" is an array with 1 element
#   And the "code" of all stack frames is null
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## send_environment
#TODO:SM Need to verify not normally sent
# Scenario Outline: Send_environment should send environment in handled errors when true
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=send_environment&value=true" on port "<port>"
#   And I navigate to the route "/unthrown_handled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "RuntimeError"
#   And the exception "message" starts with "unthrown handled error"
#   And the event "unhandled" is false
#   And the event "metaData.request.url" ends with "/unthrown_handled"
#   And the event "metaData.environment.REQUEST_METHOD" equals "GET"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |
# Scenario Outline: Send_environment should send environment in unhandled errors when true
#   Given I set environment variable "MAZE_API_KEY" to "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And I start the compose stack "features/fixtures/rails4/docker-compose.yml"
#   And I wait for the app to respond on port "<port>"
#   When I navigate to the route "/set_config_option?name=send_environment&value=true" on port "<port>"
#   And I navigate to the route "/unhandled" on port "<port>"
#   Then I should receive a request
#   And the request is a valid for the error reporting API
#   And the request used the Ruby notifier
#   And the "Bugsnag-API-Key" header equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "apiKey" equals "a35a2a72bd230ac0aa0f52715bbdc6aa"
#   And the payload field "events" is an array with 1 element
#   And the exception "errorClass" equals "NameError"
#   And the exception "message" starts with "undefined local variable or method `generate_unhandled_error' for #<ApplicationController"
#   And the event "unhandled" is true
#   And the event "metaData.request.url" ends with "/unhandled"
#   And the event "metaData.environment.REQUEST_METHOD" equals "GET"
#   And the event "app.type" equals "rails"
#
#   Examples:
#     | port |
#     | 3000 |
#     | 3001 |
#     | 3002 |
#     | 3003 |
#     | 3004 |
#     | 3005 |

## timeout
Scenario Outline: Timeout is 15 seconds by default
Scenario Outline: Timeout can be changed in the initializer
Scenario Outline: Timeout can be changed after the initializer
Scenario Outline: Timeout affects notify calls
Scenario Outline: Timeout affects session calls
Scenario Outline: App responds promptly when notify is down
Scenario Outline: App responds promptly when sessions is down

# Report
## add_tab
Scenario Outline: Can call add_tab on report to add ui tab
Scenario Outline: Can call add_tab on report to merge info in ui tab

## api_key
Scenario Outline: Can set the api_key on a report

## context
Scenario Outline: Can set the context on a report

## exceptions
Scenario Outline: Can read exceptions from a report

## grouping_hash
Scenario Outline: Can set a grouping hash on a report

## ignore!
Scenario Outline: Can ignore a report

## meta_data
Scenario Outline: Can read meta_data from a report
Scenario Outline: Can write to the meta_data in a report

## remove_tab
Scenario Outline: Can remove a tab from a report

## severity
Scenario Outline: Can set severity of a report to error
Scenario Outline: Can set severity of a report to warning
Scenario Outline: Can set severity of a report to info

## user
Scenario Outline: Can set user id in a report
Scenario Outline: Can set user email in a report
Scenario Outline: Can set user name in a report
Scenario Outline: Can set other user information in a report
Scenario Outline: Can unset user in a report
