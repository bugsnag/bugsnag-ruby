Rails.application.routes.draw do
  # Vanilla rails routing
  get '/', to: 'application#index'
  get '/crash', to: 'application#crash'
  get '/notify', to: 'application#notify'
  get '/notify_data', to: 'application#data'
  get '/notify_severity', to: 'application#severity'

  # Sidekiq routing
  get '/sidekiq', to: 'sidekiq#index'
  get '/sidekiq/crash', to: 'sidekiq#crash'
  get '/sidekiq/notify_data', to: 'sidekiq#metadata'

  # Que routing
  get '/que', to: 'que#index'
  get '/que/crash', to: 'que#crash'
  get '/que/notify_data', to: 'que#metadata'

  # Resque routing
  get '/resque', to: 'resque#index'
  get '/resque/crash', to: 'resque#crash'
  get '/resque/notify_data', to: 'resque#metadata'
end
