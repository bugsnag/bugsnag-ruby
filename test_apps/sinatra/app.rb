# app.rb
set :haml, :format => :html5

get "/" do
  haml :index
end

get "/nonfatal" do
  Bugsnag.notify(RuntimeError.new("Something broke"))
  haml :index
end

get "/fatal" do
  raise RuntimeError.new("Something broke")
  haml :index
end