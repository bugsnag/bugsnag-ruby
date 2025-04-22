class MongoModel
  include Mongoid::Document

  field :string_field, type: String
  field :numeric_field, type: Integer
end