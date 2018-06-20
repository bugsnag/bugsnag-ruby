class User < ActiveRecord::Base
  attr_accessible :email
  attr_accessible :name
  attr_accessible :first_name
  attr_accessible :last_name
end
