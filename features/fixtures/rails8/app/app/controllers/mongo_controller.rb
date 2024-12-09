class MongoController < ApplicationController
  def success_crash
    doc = MongoModel.create(string_field: "String")
    doc.save
    "Statement".prepnd("Failing")
  end

  def get_crash
    MongoModel.where(string_field: true).as_json
    MongoModel.any_of({string_field: true}, {numeric_field: 123}).as_json
    "Statement".prepnd("Failing")
  end

  def failure_crash
    begin
      Mongoid::Clients.default.database.command(:bogus => 1)
    rescue
    end

    "Statement".prepnd("Failing")
  end
end
