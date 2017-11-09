Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/', to: 'application#index'
  get '/crash', to: 'application#crash'
  get '/crash_with_callback', to: 'application#callback'
  get '/notify', to: 'application#notify'
  get '/notify_data', to: 'application#data'
  get '/notify_severity', to: 'application#severity'
end
