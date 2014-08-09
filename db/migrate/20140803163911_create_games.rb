class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.string :phase
      t.integer :turn

      t.timestamps
    end
  end
end
