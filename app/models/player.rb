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
    events << { type: "debug", all_log: "DRAWING YOU FUCKING NOIOBS" }
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
