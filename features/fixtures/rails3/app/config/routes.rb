App::Application.routes.draw do
  get "/(:action)", controller: 'application'
end
