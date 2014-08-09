class Supply < ActiveRecord::Base
  belongs_to :game
  belongs_to :card_pile, dependent: :destroy
	has_many :piles, through: :card_pile
	has_many :cards, through: :piles

	def name
		return card_pile.name
	end

end
