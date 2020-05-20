class ApplicationController < ActionController::Base
  def crash
    raise 'Bugsnag Rails demo says: It crashed! ' \
      'Go check bugsnag.com for a new notification'
  end

  def callback
    Bugsnag.before_notify_callbacks << proc { |report|
      report.add_tab(:diagnostics, {
        message: 'Rails v6.0 demo says: Everything is great',
        code: 200
      })
    }

    raise 'Bugsnag Rails demo says: It crashed! But, due to the attached callback' \
      'the exception has meta information. Go check ' \
      'bugsnag.com for a new notification (see the Diagnostics tab)!'
  end

  def notify
    Bugsnag.notify(RuntimeError.new("Bugsnag Rails demo says: False alarm, your application didn't crash"))
  end

  def data
    error = RuntimeError.new("Bugsnag Rails demo says: False alarm, your application didn't crash")

    Bugsnag.notify(error) do |report|
      report.add_tab(:user, {
        username: 'bob-hoskins',
        email: 'bugsnag@bugsnag.com',
        registered_user: true
      })

      report.add_tab(:diagnostics, {
        message: 'Rails demo says: Everything is great',
        code: 200
      })
    end
  end

  def severity
    error = RuntimeError.new(
      "Bugsnag Rails demo says: Look at the circle on the right side — it's different!"
    )

    Bugsnag.notify(error) do |report|
      report.severity = 'info'
    end
  end
end
