class FeatureFlagsController < ActionController::Base
  protect_from_forgery

  before_bugsnag_notify :add_feature_flags

  def unhandled
    Bugsnag.add_feature_flag('unhandled')

    raise 'oh no'
  end

  def handled
    Bugsnag.add_feature_flag('handled')

    Bugsnag.notify(RuntimeError.new('ahhh'))
  end

  private

  def add_feature_flags(event)
    params['flags'].each do |key, value|
      event.add_feature_flag(key, value)
    end

    if params.key?('clear_all_flags')
      event.add_metadata(:clear_all_flags, :a, 1)
    else
      event.clear_feature_flag('should be removed!')
    end
  end
end
