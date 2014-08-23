class AddSetToCardTemplate < ActiveRecord::Migration
  def change
    add_column :card_templates, :set, :string
  end
end
