class CreateTestModels < ActiveRecord::Migration
  def change
    create_table :test_models do |t|
      t.string :foo

      t.timestamps null: false
    end
  end
end
