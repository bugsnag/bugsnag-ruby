Rails.application.routes.draw do
  get "/(:action)", controller: 'application'
end
