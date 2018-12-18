class MongoModel
  include Mongoid::Document

  field :string_field, type: String
end