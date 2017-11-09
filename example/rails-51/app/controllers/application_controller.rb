class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @text = File.read(File.expand_path('app/views/index.md'))
  end

  def crash
    raise Exception.new('Bugsnag Rails demo says: It crashed! Go check ' +
      'bugsnag.com for a new notification')
  end

  def callback
    Bugsnag.before_notify_callbacks << proc { |report|
      new_tab = {
        message: 'Rails v4.2 demo says: Everything is great',
        code: 200
      }
      report.add_tab(:diagnostics, new_tab)
    }
    raise RuntimeError.new('Bugsnag Rails demo says: It crashed! But, due to the attached callback' +
      ' the exception has meta information. Go check' +
      ' bugsnag.com for a new notification (see the Diagnostics tab)!')
  end

  def notify
    Bugsnag.notify(RuntimeError.new("Bugsnag Rails demo says: False alarm, your application didn't crash"))
    @text = "Bugsnag Rack demo says: It didn't crash! " +
      'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
      ' for a new notification.'
  end

  def data
    error = RuntimeError.new("Bugsnag Rails demo says: False alarm, your application didn't crash")
    Bugsnag.notify error do |report|
      report.add_tab(:user, {
        :username => "bob-hoskins",
        :email => 'bugsnag@bugsnag.com',
        :registered_user => true
      })
      report.add_tab(:diagnostics, {
        :message => 'Rails demo says: Everything is great',
        :code => 200
      })
    end
    @text = "Bugsnag Rails demo says: It didn't crash! " +
      'But still go check <a href="https://bugsnag.com">https://bugsnag.com</a>' +
      ' for a new notification. Check out the User tab for the meta data'
  end

  def severity
    msg = "Bugsnag Rails demo says: Look at the circle on the right side. It's different"
    error = RuntimeError.new(msg)
    Bugsnag.notify error do |report|
      report.severity = 'info'
    end
    @text = msg
  end
end
