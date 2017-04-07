require 'active_record'

class User < ActiveRecord::Base
end

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql', database: ENV['DBNAME']
)
