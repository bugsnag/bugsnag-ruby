class ClearanceController < Clearance::BaseController
  protect_from_forgery

  def index
    render json: {}
  end

  def create
    user = User.find_by(:email => "testtest@test.test")
    User.new({
      :email => "testtest@test.test",
      :name => "Clearance User",
      :first_name => "Clearance",
      :last_name => "User",
      :password => "Password"
    }).save if user.nil?
    render json: {}
  end

  def unhandled
    user = User.find_by(:email => "testtest@test.test")
    unless user.nil?
      @current_user = user
      cookies['remember_token'] = user.remember_token
    end
    generate_unhandled_error
  end

  def handled
    user = User.find_by(:email => "testtest@test.test")
    unless user.nil?
      @current_user = user
      cookies['remember_token'] = user.remember_token
    end
    Bugsnag.notify("handled string")
    render json: {}
  end
end
