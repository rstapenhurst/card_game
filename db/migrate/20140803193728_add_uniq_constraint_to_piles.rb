class AddUniqConstraintToPiles < ActiveRecord::Migration
  def change
		remove_index :piles, :card_id
		add_index :piles, :card_id, unique: true
  end
end
