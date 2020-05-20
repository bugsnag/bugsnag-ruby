class QueCallback < Que::Job
  @run_at = proc { 5.seconds.from_now }

  def run(_options = {})
    Bugsnag.before_notify_callbacks << proc { |report|
      report.add_tab(:diagnostics, {
        message: 'Que demo says: Everything is great',
        code: 200
      })
    }

    raise 'Oh no!'
  end
end
