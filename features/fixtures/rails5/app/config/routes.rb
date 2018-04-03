Rails.application.routes.draw do
  get "/unhandled/(:action)", controller: 'unhandled'
  get "/handled/(:action)", controller: 'handled'
  get "/before_notify/(:action)", controller: 'before_notify'
end
