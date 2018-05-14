App::Application.routes.draw do
  devise_for :users
  get "/", to: 'application#index'
  get "/unhandled/(:action)", controller: 'unhandled'
  get "/handled/(:action)", controller: 'handled'
  get "/before_notify/(:action)", controller: 'before_notify'
  get "/api_key/(:action)", controller: 'api_key'
  get "/app_type/(:action)", controller: 'app_type'
  get "/app_version/(:action)", controller: 'app_version'
  get "/auto_notify/(:action)", controller: 'auto_notify'
  get "/project_root/(:action)", controller: 'project_root'
  get "/ignore_classes/(:action)", controller: 'ignore_classes'
  get "/metadata_filters/(:action)", controller: 'metadata_filters'
  get "/session_tracking/(:action)", controller: 'session_tracking'
  get "/release_stage/(:action)", controller: 'release_stage'
  get "/send_code/(:action)", controller: 'send_code'
  get "/send_environment/(:action)", controller: 'send_environment'
  get "/devise/(:action)", controller: 'devise'
end
