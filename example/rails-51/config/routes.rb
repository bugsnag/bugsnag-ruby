Rails.application.routes.draw do
  # Vanilla rails routing
  get '/', to: 'application#index'
  get '/crash', to: 'application#crash'
  get '/crash_with_callback', to: 'application#callback'
  get '/notify', to: 'application#notify'
  get '/notify_data', to: 'application#data'
  get '/notify_severity', to: 'application#severity'

  # Sidekiq routing
  get '/sidekiq', to: 'sidekiq#index'
  get '/sidekiq/crash', to: 'sidekiq#crash'
  get '/sidekiq/notify_data', to: 'sidekiq#metadata'
  get '/sidekiq/crash_with_callback', to: 'sidekiq#callbacks'

  # Que routing

  # Resque routing
  get '/resque', to: 'resque#index'
  get '/resque/crash', to: 'resque#crash'
  get '/resque/notify_data', to: 'resque#metadata'
  get '/resque/crash_with_callback', to: 'resque#callbacks'
end
