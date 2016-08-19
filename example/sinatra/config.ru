require 'bundler'
Bundler.require

use Bugsnag::Rack

set :raise_errors, true
set :show_exceptions, false

Bugsnag.configure do |config|
  config.api_key = 'f35a2472bd230ac0ab0f52715bbdc65d'
end

get '/' do
  opts = {
    fenced_code_blocks: true
  }
  renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, opts)
  renderer.render(File.read(File.expand_path('README.md')))
end

get '/crash' do
  raise RuntimeError.new('Bugsnag Sinatra demo says: It crashed! Go check ' +
    'bugsnag.com for a new notification!')
end

get '/crash_with_callback' do
  Bugsnag.before_notify_callbacks << proc { |notification|
    new_tab = {
      message: 'Sinatra demo says: Everything is great',
      code: 200
    }
    notification.add_tab(:diagnostics, new_tab)
  }

  msg = 'Bugsnag Sinatra demo says: It crashed! But, due to the attached callback' +
    ' the exception has meta information. Go check' +
    ' bugsnag.com for a new notification (see the Diagnostics tab)!'
  raise RuntimeError.new(msg)
end

get '/notify' do
  Bugsnag.notify(RuntimeError.new("Bugsnag Sinatra demo says: False alarm, your application didn't crash"))

  "Bugsnag Sinatra demo says: It didn't crash! " +
    'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
    ' for a new notification.'
end

get '/notify_meta' do
  meta_data = {
    :user => {
      :username => "bob-hoskins",
      :email => 'bugsnag@bugsnag.com',
      :registered_user => true
    },

    :diagnostics => {
      :message => 'Sinatra demo says: Everything is great',
      :code => 200
    }
  }
  error = RuntimeError.new("Bugsnag Sinatra demo says: False alarm, your application didn't crash")
  Bugsnag.notify(error, meta_data)

  "Bugsnag Sinatra demo says: It didn't crash! " +
    'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
    ' for a new notification. Check out the User tab for the meta data'
end

get '/severity' do
  msg = "Bugsnag Sinatra demo says: Look at the circle on the right side. It's different"
  error = RuntimeError.new(msg)
  Bugsnag.notify(error, severity: 'info')
  msg
end

run Sinatra::Application
