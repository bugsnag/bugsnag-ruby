class JobController < ApplicationController
  def working
    WorkingJob.perform_later

    render json: { result: 'queued WorkingJob!' }
  end

  def unhandled
    UnhandledJob.perform_later

    render json: { result: 'queued UnhandledJob!' }
  end
end
