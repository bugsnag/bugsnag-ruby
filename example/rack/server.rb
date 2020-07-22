require 'rack'
require 'rack/request'
require 'rack/response'

require 'bugsnag'
require 'redcarpet'

Bugsnag.configure do |config|
  config.api_key = 'YOUR_API_KEY'

  config.add_on_error(proc do |report|
    report.add_tab(:user, {
      username: 'bob-hoskins',
      email: 'bugsnag@bugsnag.com',
      registered_user: true
    })
  end)
end

class BugsnagDemo
  def call(env)
    req = Rack::Request.new(env)

    case req.env['REQUEST_PATH']
    when '/crash'
      raise RuntimeError.new('Bugsnag Rack demo says: It crashed! Go check ' +
        'bugsnag.com for a new notification!')
    when '/notify'
      Bugsnag.notify(RuntimeError.new("Bugsnag Rack demo says: False alarm, your application didn't crash"))

      text = "Bugsnag Rack demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification.'
    when '/notify_data'
      error = RuntimeError.new("Bugsnag Rack demo says: False alarm, your application didn't crash")
      Bugsnag.notify(error) do |report|
        report.add_tab(:diagnostics, {
          message: 'Padrino demo says: Everything is great',
          code: 200
        })
      end

      text = "Bugsnag Rack demo says: It didn't crash! " +
        'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
        ' for a new notification. Check out the Diagnostics tab for the meta data'
    when '/notify_severity'
      msg = "Bugsnag Rack demo says: Look at the circle on the right side. It's different"
      error = RuntimeError.new(msg)
      Bugsnag.notify error do |report|
        report.severity = 'info'
      end
      text = msg
    else
      opts = {
        fenced_code_blocks: true
      }
      renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, opts)
      text = renderer.render(File.read(File.expand_path('templates/index.md')))
    end

    res = Rack::Response.new
    res.write '<title>Bugsnag Rack demo</title>'
    res.write text
    res.finish
  end
end

Rack::Server.start(app: Bugsnag::Rack.new(BugsnagDemo.new))
