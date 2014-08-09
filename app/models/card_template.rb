class CardTemplate < ActiveRecord::Base

	has_many :card_attributes, dependent: :destroy
	has_many :cards, dependent: :destroy

end
