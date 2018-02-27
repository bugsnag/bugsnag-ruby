Rails.application.routes.draw do
  root :to => 'application#index'
  get "log" => 'application#crash_after_log'
  
  get 'crash' => 'application#crash'
  get 'crash_with_callback' => 'application#callback'
  get 'notify' => 'application#notify'
  get 'notify_data' => 'application#data'
  get 'notify_severity' => 'application#severity'

end
