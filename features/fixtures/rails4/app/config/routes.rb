App::Application.routes.draw do
  get "/unhandled/(:action)", controller: 'unhandled'
  get "/handled/(:action)", controller: 'handled'
end
