class CreateSupplies < ActiveRecord::Migration
  def change
    create_table :supplies do |t|
      t.references :game, index: true
      t.string :supply_type
      t.references :card_pile, index: true

      t.timestamps
    end
  end
end
