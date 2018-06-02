require './app/jobs/que_crash'

class QueController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @text = File.read(File.expand_path('app/views/que.md'))
  end

  def crash
    QueCrash.enqueue
    @text = "Que has queued the crash task"
  end

  def callbacks
    QueCallback.enqueue
    @text = "Que has queued the callbacks task"
  end
end
