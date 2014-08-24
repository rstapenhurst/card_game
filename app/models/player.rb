class Player < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
	belongs_to :deck, class_name:"CardPile", dependent: :destroy
	belongs_to :hand, class_name:"CardPile", dependent: :destroy
	belongs_to :revealed, class_name:"CardPile", dependent: :destroy
	belongs_to :play_area, class_name:"CardPile", dependent: :destroy
	belongs_to :discard, class_name:"CardPile", dependent: :destroy
	has_many :player_attributes, dependent: :destroy

	def name
		return user.name
	end

	def predraw(events)
		if deck.is_empty
			if (discard.is_empty)
				return
			end
			discard.cards.each do |card|
				deck.add_card(card)
			end
			events << {
				type: 'recycle_deck',
				all_log: {
					player: self.name,
					size: deck.cards.count
				}
			} 
			deck.shuffle
		end
	end

	def draw(count, events)
		count.times() do
			predraw(events)
			card = deck.top_card
			hand.add_card(card)

      events << {
        type: 'move_card',
        all_log: {
          from_player: name,
          from_zone: "deck",
          from_size: deck.cards.count,
          to_player: name,
          to_zone: "hand",
          to_size: hand.cards.count,
        },
        logs_by_id: [{
					owner_id: id,
          to_card: card.view
        }]
      }
		end
	end

	def reveal_from_deck(events)
		predraw(events)
		return move_public('deck', 'revealed', events)
	end

	def pile_by_name(pile_name)
		send(pile_name)
	end

	def move_public(from_pile_name, to_pile_name, events)
		next_card = pile_by_name(from_pile_name).top_card
		return move_card_public(next_card, from_pile_name, to_pile_name, events)
	end

	def move_card_public(card, to_pile_name, events)
		from_pile_name = get_pile_name(card.card_pile)
		return move_card_public(card, from_pile_name, to_pile_name, events)
	end

	def move_card_public(card, from_pile_name, to_pile_name, events)
		from = pile_by_name(from_pile_name)
		to = pile_by_name(to_pile_name)
		to.add_card(card)
		new_top = from.top_card
		events << {
			type: "move_card",
			all_log: {
				from_player: name,
				from_zone: from_pile_name,
				from_size: from.cards.count,
				from_card: card.view,
				revealed: new_top && new_top.view,
				to_player: name,
				to_zone: to_pile_name,
				to_size: to.cards.count,
				to_card: card.view
			}
		}
		return next_card
	end

	def get_pile_name(card_pile)
		if draw == card_pile
			return 'draw'
		elsif discard == card_pile
			return 'discard'
		elsif revealed == card_pile
			return 'revealed'
		elsif hand == card_pile
			return 'hand'
		end
	end

	def get_attrib(attrib)
		player_attributes.where(key: attrib).pluck(:value).first
	end

	def method_missing(meth, *args, &block)
		method_name = meth.to_s
		if ( method_name =~ /set_(.*)/ )
			method_name.slice! 'set_'
			attr = PlayerAttribute.where(player_id: id, key: method_name).take
			if (attr == nil)
				PlayerAttribute.create(
					player: self,
					key: method_name,
					value: args[0]
				);
			else
				attr.value = args[0]
				attr.save
			end
			return
		else
			attribute = player_attributes.where(key: method_name).take
			if attribute
				return attribute.value
			else
				return nil
			end
		end
	end

end
