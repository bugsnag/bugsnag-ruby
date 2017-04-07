require 'active_record'
require_relative 'model'
require 'que'
require 'bugsnag'

Bugsnag.configure do |config|
  config.api_key = 'f35a2472bd230ac0ab0f52715bbdc65d'
end

Que.connection = ActiveRecord

class Cheer < Que::Job
  @run_at = proc { 5.seconds.from_now }

  def run(user_id, options={})
    user = User.find(user_id)

    ActiveRecord::Base.transaction do
      user.update_attributes cheered_at: Time.now

      raise 'Oh no, a problem!'
      destroy
    end
  end
end
