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

	def play_card(player, card)
		player.play_area.add_card(card)
		if card.is_action == 1
			player.set_actions(player.actions - 1)
		end
		card.card_attributes.each do |attr|
			if (attr.key == "money")
				player.set_money(player.money + attr.value)
			elsif (attr.key == "actions")
				player.set_actions(player.actions + attr.value)
			elsif (attr.key == "buys")
				player.set_buys(player.buys + attr.value)
			elsif (attr.key == "cards")
				player.draw(attr.value)
			end
		end
		check_auto_advance
	end

	def buy_card(player, supply)
		candidate_card = supply.card_pile.top_card
		if player.money >= candidate_card.cost and player.buys >= 1
			player.discard.add_card(candidate_card)
			current_money = player.money - candidate_card.cost
			player.set_money(current_money)
			current_buys = player.buys - 1
			player.set_buys(current_buys)

			if supply.name == "Province" and supply.card_pile.is_empty
				self.phase = "Finished"
				save
			end
			check_auto_advance
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
			player.draw(5)
		end
	end

	def setup_supplies
		add_supply('Copper', 'treasure', 10)
		add_supply('Silver', 'treasure', 10)
		add_supply('Gold', 'treasure', 10)

		add_supply('Estate', 'victory', 8)
		add_supply('Duchy', 'victory', 8)
		add_supply('Province', 'victory', 8)

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

	def advance_phase
		if phase == 'init'
			setup_decks
			setup_supplies
			self.phase = 'action'
		elsif phase == 'action'
			self.phase = 'treasure'
		elsif phase == 'treasure'
			self.phase = 'buy'
		elsif phase == 'buy'
			self.phase = 'cleanup'
			do_cleanup
		end
		check_auto_advance
		save
	end

	def check_auto_advance
		if self.phase == 'action'
			if current_player.actions == 0 or !current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_action" AND card_attributes.value == 1').exists?
				advance_phase
			end
		elsif self.phase == 'treasure'
			if !current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_treasure" AND card_attributes.value == 1').exists?
				advance_phase
			end
		elsif self.phase == 'buy'
			if current_player.buys == 0
				advance_phase
			end
		end
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

		if phase == "init"
			return false
		end

		if phase == "action" and card.is_action == 0 and player.actions >= 1
			return false
		end

		if phase == "treasure" and card.is_treasure == 0
			return false
		end

		return true
	end

	def do_cleanup
		player = current_player
		player.play_area.cards.each do |card|
			player.discard.add_card(card)
		end
		player.hand.cards.each do |card|
			player.discard.add_card(card)
		end
		player.draw(5)
		player.set_money(0)
		player.set_buys(1)
		player.set_actions(1)

		self.turn += 1
		self.phase = 'action'
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
				actions: current_player.actions,
				buys: current_player.buys,
				money: current_player.money
			},
			trash: {
				size: trash.cards.count
			}.merge!(trash.is_empty ? {} : { topcard: trash.top_card.view }),
			phase: phase,
			turn: turn
		}
	end

end
