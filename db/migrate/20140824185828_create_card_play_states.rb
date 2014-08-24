class CreateCardPlayStates < ActiveRecord::Migration
  def change
    create_table :card_play_states do |t|
      t.references :game, index: true
      t.references :card, index: true
      t.integer :order
      t.integer :current_attribute

      t.timestamps
    end
  end
end
