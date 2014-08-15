class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :game
      t.integer :event_index
      t.text :event

      t.timestamps
    end
  end
end
