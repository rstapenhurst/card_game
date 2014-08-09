class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.references :game, index: true
      t.references :user, index: true
      t.integer :play_order
      t.references :deck
      t.references :hand
      t.references :play_area
      t.references :discard

      t.timestamps
    end
  end
end
