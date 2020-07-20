require './app/jobs/que_crash'
require './app/jobs/que_callback'

class QueController < ActionController::Base
  layout "application"

  def crash
    QueCrash.enqueue
  end

  def callbacks
    QueCallback.enqueue
  end
end
