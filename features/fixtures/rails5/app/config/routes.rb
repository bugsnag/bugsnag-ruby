Rails.application.routes.draw do
  get "/unhandled/(:action)", controller: 'unhandled'
  get "/handled/(:action)", controller: 'handled'
  get "/before_notify/(:action)", controller: 'before_notify'
  get "/api_key/(:action)", controller: 'api_key'
  get "/app_type/(:action)", controller: 'app_type'
  get "/app_version/(:action)", controller: 'app_version'
end
