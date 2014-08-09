class CreatePiles < ActiveRecord::Migration
  def change
    create_table :piles do |t|
      t.references :card_pile, index: true
      t.references :card, index: true
      t.integer :card_order

      t.timestamps
    end
  end
end
