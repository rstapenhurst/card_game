class CreateCardAttributes < ActiveRecord::Migration
  def change
    create_table :card_attributes do |t|
      t.references :card_template, index: true
      t.string :attribute
      t.integer :value
      t.integer :attribute_order

      t.timestamps
    end
  end
end
