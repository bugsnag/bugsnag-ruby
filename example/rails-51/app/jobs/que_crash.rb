class QueCrash < Que::Job
  @run_at = proc { 5.seconds.from_now }

  def run(options={})
    raise "Oh no"
  end
end
