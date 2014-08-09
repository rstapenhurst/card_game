class CreateCardPiles < ActiveRecord::Migration
  def change
    create_table :card_piles do |t|
      t.string :name

      t.timestamps
    end
  end
end
