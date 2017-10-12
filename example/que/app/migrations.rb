require 'active_record'
require_relative 'model'

class CreateUsersTable < ActiveRecord::Migration[5.1]
  def up
    create_table :users do |t|
      t.string :name
      t.date :cheered_at
    end
  end

  def down
    drop_table :users
  end
end