require Rails.root.join('app/models/user')

class TokenStrategy < ::Warden::Strategies::Base
  def valid?
    params['email']
  end

  def authenticate!
    user = User.where(:email => params['email']).to_a.first
    success!(user) unless user.nil?
  end
end