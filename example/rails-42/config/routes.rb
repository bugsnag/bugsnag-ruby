Rails.application.routes.draw do
  root :to => 'application#index'

  get 'crash' => 'application#crash'
  get 'notify' => 'application#notify'
  get 'notify_data' => 'application#data'
  get 'notify_severity' => 'application#severity'
end
