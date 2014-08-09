class CreateCardTemplates < ActiveRecord::Migration
  def change
    create_table :card_templates do |t|
      t.string :name

      t.timestamps
    end
  end
end
