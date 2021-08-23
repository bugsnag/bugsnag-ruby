Rails.application.routes.draw do
  get '/job/working', 'job#working'
  get '/job/unhandled', 'job#unhandled'
end
