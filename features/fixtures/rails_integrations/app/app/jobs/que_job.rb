class QueJob < Que::Job
  def run
    raise 'oops!'
  end
end
