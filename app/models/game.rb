class Game < ActiveRecord::Base
	has_many :players, dependent: :destroy
	has_many :supplies, dependent: :destroy
	has_many :cards, dependent: :destroy
	belongs_to :trash, class_name:"CardPile", dependent: :destroy

	def create_player_for_user(user_id)
		user = User.find(user_id)

		deck = CardPile.create(name: "Deck (game: #{name}, user: #{user.name})")
		hand = CardPile.create(name: "Hand(game: #{name}, user: #{user.name})")
		discard = CardPile.create(name: "Discard (game: #{name}, user: #{user.name})")
		play_area = CardPile.create(name: "Play Area (game: #{name}, user: #{user.name})")
		play_order = Player.where(game_id: id).count()
		player = Player.create(
			game_id: id,
			user_id: user.id,
			deck_id: deck.id,
			hand_id: hand.id,
			discard_id: discard.id,
			play_area_id: play_area.id,
			play_order: play_order)
		player.set_money(0)
		player.set_buys(1)
		player.set_actions(1)

	end

	def play_card(player, card, events)

		player.play_area.add_card(card)
		events << {
			player_log: "Removed #{card.name} from #{player.hand.name}",
			opponent_log: "Set #{player.hand.name} to #{player.hand.cards.count} cards"
		} << {
			all_log: "Added #{card.name} to #{player.play_area.name}"
		}

		dirty_actions = dirty_money = dirty_buys = false
		if card.is_action == 1
			player.set_actions(player.actions - 1)
			dirty_actions = true
		end
		card.card_attributes.each do |attr|
			if (attr.key == "money")
				player.set_money(player.money + attr.value)
				dirty_money = true
			elsif (attr.key == "actions")
				player.set_actions(player.actions + attr.value)
				dirty_actions = true
			elsif (attr.key == "buys")
				player.set_buys(player.buys + attr.value)
				dirty_buys = true
			elsif (attr.key == "cards")
				player.draw(attr.value, events)
			end
		end
		events << {
			all_log: "Set player money to #{player.money}"
		} if dirty_money
	  events << {
			all_log: "Set player actions to #{player.actions}"
		} if dirty_actions
		events << {
			all_log: "Set player buys to #{player.buys}"
		} if dirty_buys
		check_auto_advance(events)
	end

	def buy_card(player, supply, events)
		candidate_card = supply.card_pile.top_card
		if player.money >= candidate_card.cost and player.buys >= 1
			player.discard.add_card(candidate_card)
			events << {
				all_log: "Added #{candidate_card.name} on top of #{player.discard.name}"
			}
			events << {
				all_log: "Set #{player.discard.name} to #{player.discard.cards.count} cards"
			}
			player.set_money(player.money - candidate_card.cost)
			events << {
				all_log: "Set player money to #{player.money}"
			} if candidate_card.cost > 0
			player.set_buys(player.buys - 1)
			events << {
				all_log: "Set player buys to #{player.buys}"
			}

			check_auto_advance(events)
		end
	end

	def setup_decks
		players.each do |player|
			7.times() do
				copper = create_card("Copper")
				player.deck.add_card(copper)
			end
			3.times() do
				estate = create_card("Estate")
				player.deck.add_card(estate)
			end
			player.deck.shuffle
			player.draw(5, [])
		end
	end

	def setup_supplies
		add_supply('Copper', 'treasure', 10)
		add_supply('Silver', 'treasure', 10)
		add_supply('Gold', 'treasure', 10)

		add_supply('Estate', 'victory', 10)
		add_supply('Duchy', 'victory', 10)
		add_supply('Province', 'victory', 10)

		add_supply('Village', 'kingdom', 10)
		add_supply('Smithy', 'kingdom', 10)
		add_supply('Festival', 'kingdom', 10)
		add_supply('Market', 'kingdom', 10)
		add_supply('Laboratory', 'kingdom', 10)
	end

	def add_supply(name, type, count)
		card_pile = CardPile.create(name: name);
		supply = Supply.create(
			game: self,
			supply_type: type,
			card_pile: card_pile
		);
		count.times() do
			card = create_card(name)
			card_pile.add_card(card)
		end
	end

	def create_card(template_name)
		card_template = CardTemplate.where(name: template_name).take()
		card = Card.create(
			card_template_id: card_template.id,
			game_id: id 
			);
		return card
	end

	def advance_phase(events)
		if phase == 'init'
			setup_decks
			setup_supplies
			set_phase('action', events)
		elsif phase == 'action'
			set_phase('treasure', events)
		elsif phase == 'treasure'
			set_phase('buy', events)
		elsif phase == 'buy'
			set_phase('cleanup', events)
			do_cleanup(events)
		elsif phase == 'cleanup'
			set_phase('action', events)
		end
		check_auto_advance(events)
		save
	end

	def set_phase(new_phase, events)
		self.phase = new_phase
		events << {
			all_log: "Set phase to #{phase}"
		}
	end

	def check_auto_advance(events)
		if self.phase == 'action'
			if current_player.actions == 0 or !current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_action" AND card_attributes.value == 1').exists?
				advance_phase(events)
			end
		elsif self.phase == 'treasure'
			if !current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_treasure" AND card_attributes.value == 1').exists?
				advance_phase(events)
			end
		elsif self.phase == 'buy'
			if current_player.buys == 0
				advance_phase(events)
			end
		elsif self.phase == 'cleanup'
			advance_phase(events)
		end

		check_victory(events)
	end

	def check_victory(events)
		empty_pile_count = 0
		provinces_empty = false
		supplies.each do |supply|
			if supply.card_pile.is_empty
				empty_pile_count += 1
				if (supply.name == "Province")
					provinces_empty = true
				end
			end
		end
		puts "Victory? Empty piles: #{empty_pile_count}, provs: #{provinces_empty}"
		if empty_pile_count >= 3 or provinces_empty
			set_phase('finished', events)
			players.each do |player|
				victory = count_points_in_pile(player.deck) +
					count_points_in_pile(player.discard) +
					count_points_in_pile(player.hand) +
					count_points_in_pile(player.play_area)
				events << {
					all_log: "Player #{player.name} has #{victory} victory points"
				}
			end
		end
	end

	def count_points_in_pile(pile)
		victory = 0
		pile.cards.each do |card|
			if card.has_attr('victory_points')
				victory += card.victory_points
			end
		end
		return victory
	end

	def current_player_query
		Player.where(game_id: id, play_order: turn % player_count)
	end

	def current_player
		current_player_query.take
	end

	def player_count
		Player.where(game_id: id).count()
	end

	def is_players_turn(player)
		player.id == current_player_query.take.id
	end

	def is_legal(player, card)
		if !is_players_turn(player)
			return false
		end

		if player.hand.cards.where(id: card.id).count == 0
			return false
		end

		if phase == 'init'
			return false
		end

		if phase == 'action' and card.is_action == 0 and player.actions >= 1
			return false
		end

		if phase == 'treasure' and card.is_treasure == 0
			return false
		end

		if phase == 'buy'
			return false
		end

		return true
	end

	def do_cleanup(events)
		player = current_player
		player.play_area.cards.each do |card|
			player.discard.add_card(card)
		end

		player.hand.cards.each do |card|
			player.discard.add_card(card)
		end
		player.draw(5, [])
		player.set_money(0)
		player.set_buys(1)
		player.set_actions(1)

		self.turn += 1
	end

	def view_for(player)
		return :game => {
			supplies: supplies.collect{|supply|
				{
					id: supply.id,
					size: supply.cards.count
				}.merge!(supply.card_pile.is_empty ? {} : { top: supply.card_pile.top_card.view })
			},
			opponents: players.select{|candidate| candidate != player}.collect{|opponent|
				{
					name: opponent.name,
					id: opponent.id,
					deck_size: opponent.deck.cards.count,
					discard: {
						id: opponent.discard.id,
						size: opponent.discard.cards.count,
					}.merge!(opponent.discard.is_empty ? {} : { top: opponent.discard.top_card.view }),
					hand_size: opponent.hand.cards.count,
				}
			},
			player: {
				name: player.name,
				id: player.id,
				deck_size: player.deck.cards.count,
				discard: {
					id: player.discard.id,
					size: player.discard.cards.count,
				}.merge!(player.discard.is_empty ? {} : { top: player.discard.top_card.view }),
				hand: player.hand.ordered_cards.collect{|hand_card|
					hand_card.view
				},
			},
			play_area: current_player.play_area.ordered_cards.collect{|played_card|
				played_card.view
			},
			current_player: {
				id: current_player.id,
				name: current_player.name,
				actions: current_player.actions,
				buys: current_player.buys,
				money: current_player.money
			},
			trash: {
				id: trash.id,
				size: trash.cards.count
			}.merge!(trash.is_empty ? {} : { topcard: trash.top_card.view }),
			phase: phase,
			turn: turn
		}
	end

end
