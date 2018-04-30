class UnhandledController < ActionController::Base
  protect_from_forgery with: :exception

  def error
    generate_unhandled_error
  end
end
