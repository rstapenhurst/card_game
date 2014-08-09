class RenameAttributeToKeyInCardAttributes < ActiveRecord::Migration
  def change
		rename_column :card_attributes, :attribute, :key
  end
end
