class AddTempToPlayer < ActiveRecord::Migration
  def change
		add_column :players, :revealed_id, :integer, references: :card_piles
  end
end
