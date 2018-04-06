App::Application.routes.draw do
  get "/unhandled/(:action)", controller: 'unhandled'
  get "/handled/(:action)", controller: 'handled'
  get "/before_notify/(:action)", controller: 'before_notify'
  get "/api_key/(:action)", controller: 'api_key'
  get "/app_type/(:action)", controller: 'app_type'
  get "/app_version/(:action)", controller: 'app_version'
  get "/auto_notify/(:action)", controller: 'auto_notify'
  get "/project_root/(:action)", controller: 'project_root'
  get "/ignore_classes/(:action)", controller: 'ignore_classes'
end
