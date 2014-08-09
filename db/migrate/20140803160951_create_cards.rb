class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.references :card_template, index: true

      t.timestamps
    end
  end
end
