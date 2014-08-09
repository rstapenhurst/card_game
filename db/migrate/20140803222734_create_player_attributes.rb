class CreatePlayerAttributes < ActiveRecord::Migration
  def change
    create_table :player_attributes do |t|
      t.references :player
      t.string :key
      t.integer :value

      t.timestamps
    end
  end
end
