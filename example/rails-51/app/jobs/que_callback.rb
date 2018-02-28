class QueCallback < Que::Job
  @run_at = proc { 5.seconds.from_now }

  def run(options={})
    Bugsnag.before_notify_callbacks << proc { |report|
      new_tab = {
        message: 'Que demo says: Everything is great',
        code: 200
      }
      report.add_tab(:diagnostics, new_tab)
    }
    raise "Oh no"
  end
end
