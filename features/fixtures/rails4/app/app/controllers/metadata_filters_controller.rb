class MetadataFiltersController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def filter
    Bugsnag.notify("handled string") do |report|
      report.add_tab(:my_specific_filter, {
        :foo => "bar"
      })
    end
    render json: {}
  end
end
