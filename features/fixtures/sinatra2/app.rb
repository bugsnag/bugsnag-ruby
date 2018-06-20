require 'bundler'
Bundler.require

set bind: '0.0.0.0'
set port: 3000

get '/' do
  'Hello world!'
end
