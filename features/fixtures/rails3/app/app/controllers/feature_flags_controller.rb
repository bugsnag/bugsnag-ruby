class FeatureFlagsController < ActionController::Base
  protect_from_forgery

  before_bugsnag_notify :add_feature_flags

  def unhandled
    raise 'oh no'
  end

  def handled
    Bugsnag.notify(RuntimeError.new('ahhh'))

    render json: {}
  end

  private

  def add_feature_flags(event)
    params['flags'].each do |key, value|
      event.add_feature_flag(key, value)
    end

    if params.key?('clear_all_flags')
      event.clear_feature_flags
    else
      event.clear_feature_flag('should be removed!')
    end
  end
end
