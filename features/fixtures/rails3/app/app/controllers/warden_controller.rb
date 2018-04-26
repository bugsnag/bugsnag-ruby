class WardenController < ActionController::Base
  protect_from_forgery

  def index
    render json: {}
  end

  def create
    User.new({
      :email => "testtest@test.test",
      :name => "Warden User",
      :first_name => "Warden",
      :last_name => "User"
    }).save unless User.where(:email => "testtest@test.test").size > 0
    render json: {}
  end

  def unhandled
    warden = request.env['warden']
    warden.authenticate!
    generate_unhandled_error
  end

  def handled
    warden = request.env['warden']
    warden.authenticate!
    Bugsnag.notify("handled string")
    render json: {}
  end
end
