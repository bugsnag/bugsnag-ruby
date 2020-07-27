require './app/jobs/que_crash'

class QueController < ActionController::Base
  layout "application"

  def crash
    QueCrash.enqueue
  end
end
