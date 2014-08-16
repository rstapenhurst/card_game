class CardPile < ActiveRecord::Base
	has_many :piles, dependent: :destroy
	has_many :cards, through: :piles

	def add_card(card)
		card_order = Pile.where(card_pile_id: id).count()
		pile = Pile.where(card_id: card.id).take()
		if pile
			pile.card_pile_id = id
			pile.card_order = card_order
			pile.save
		else
			Pile.create(
				card_id: card.id,
				card_pile_id: id,
				card_order: card_order
			);
		end

	end

	def shuffle
		index = 0
		piles.shuffle.each do |pile|
			pile.card_order = index
			pile.save
			index += 1
		end
	end

	def top_card
    if is_empty
      return nil
    else
      card = Pile.where(card_pile_id: id).order("card_order DESC").first().card
      return card
    end
	end

	def is_empty
		return !Pile.exists?(card_pile_id: id)
	end

	def ordered_cards
		return piles.collect{|pile|
			{
				card_order: pile.card_order,
				card: pile.card
			}
		}.sort!{|a,b|
			a[:card_order] <=> b[:card_order]
		}.collect{|sorted_card|
			sorted_card[:card]
		}
	end
end
