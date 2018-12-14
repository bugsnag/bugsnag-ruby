require './app/models/mongo_model'

class MongoController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    render json: {}
  end

  def crash
    test_doc = Test.create(string_field: "String")
    test_doc.save
    "Statement".prepnd("Failing")
  end
end
