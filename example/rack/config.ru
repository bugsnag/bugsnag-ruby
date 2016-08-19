require 'rack'
require 'rack/showexceptions'
require 'rack/request'
require 'rack/response'

require 'bugsnag'
require 'redcarpet'


Bugsnag.configure do |config|
  config.api_key = 'f35a2472bd230ac0ab0f52715bbdc65d'
end

class BugsnagDemo
  def call(env)
    req = Rack::Request.new(env)

    case req.env['REQUEST_PATH']
    when '/crash'
      raise RuntimeError.new('Bugsnag Rack demo says: It crashed! Go check ' +
        'bugsnag.com for a new notification!')
    when '/crash_with_callback'
      Bugsnag.before_notify_callbacks << proc { |notification|
        new_tab = {
          message: 'Rack demo says: Everything is great',
          code: 200
        }
        notification.add_tab(:diagnostics, new_tab)
      }

      msg = 'Bugsnag Rack demo says: It crashed! But, due to the attached callback' +
        ' the exception has meta information. Go check' +
        ' bugsnag.com for a new notification (see the Diagnostics tab)!'
      raise RuntimeError.new(msg)
    when '/notify'
      Bugsnag.notify(RuntimeError.new("Bugsnag Rack demo says: False alarm, your application didn't crash"))

      text = "Bugsnag Rack demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification.'
    when '/notify_meta'
      meta_data = {
        :user => {
          :username => "bob-hoskins",
          :email => 'bugsnag@bugsnag.com',
          :registered_user => true
        },

        :diagnostics => {
          :message => 'Rack demo says: Everything is great',
          :code => 200
        }
      }
      error = RuntimeError.new("Bugsnag Rack demo says: False alarm, your application didn't crash")
      Bugsnag.notify(error, meta_data)

      text = "Bugsnag Rack demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification. Check out the User tab for the meta data'
    when '/severity'
      msg = "Bugsnag Rack demo says: Look at the circle on the right side. It's different"
      error = RuntimeError.new(msg)
      Bugsnag.notify(error, severity: 'info')
      msg
    else
      opts = {
        fenced_code_blocks: true
      }
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, opts)
      text = renderer.render(File.read(File.expand_path('README.md')))
    end

    res = Rack::Response.new
    res.write '<title>Bugsnag Rack demo</title>'
    res.write text
    res.finish
  end
end

Rack::Server.start(app: Bugsnag::Rack.new(BugsnagDemo.new))
