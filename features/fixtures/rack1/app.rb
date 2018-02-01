require 'bundler'
Bundler.require

app = Proc.new do |env|
    ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
end

Rack::Handler::WEBrick.run app, {Port: 3000, BindAddress: '0.0.0.0'}
