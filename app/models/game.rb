require 'specials'

class Game < ActiveRecord::Base
	has_many :players, dependent: :destroy
	has_many :supplies, dependent: :destroy
	has_many :cards, dependent: :destroy
	has_many :events, dependent: :destroy
	has_many :dialogs, dependent: :destroy
	has_many :card_play_states, dependent: :destroy
	belongs_to :trash, class_name:"CardPile", dependent: :destroy

	def card_states
		card_play_states.order(:play_order)
	end

	def print_card_stack
		log_line = "Card stack: "
		card_states.each do |state|
			log_line << "->#{state.card.name}@#{state.current_attribute}"
		end
		puts log_line
	end

	def current_state
		card_states.take
	end

	def push_card_state(player, card, current_attribute)
		CardPlayState.create(game: self, player: player, card: card, play_order: card_play_states.count + 1, current_attribute: current_attribute)
	end

	def pop_card_state
		puts "Popping card state"
		current_state.destroy
	end

	def set_current_attribute(current_attribute)
		state = current_state
		state.current_attribute = current_attribute
		state.save
	end

	def continue_card(events)
		state = current_state
		play_card_from_attribute(state.player, state.card, state.current_attribute + 1, events)
	end

	def create_player_for_user(user_id)
		puts "Creating player for user #{user_id}"
		user = User.find(user_id)

		deck = CardPile.create(name: "Deck (game: #{name}, user: #{user.name})")
		hand = CardPile.create(name: "Hand(game: #{name}, user: #{user.name})")
		discard = CardPile.create(name: "Discard (game: #{name}, user: #{user.name})")
		play_area = CardPile.create(name: "Play Area (game: #{name}, user: #{user.name})")
		revealed = CardPile.create(name: "Revealed Cards (game: #{name}, user: #{user.name})")
		play_order = Player.where(game_id: id).count()
		player = Player.create(
			game_id: id,
			user_id: user.id,
			deck_id: deck.id,
			hand_id: hand.id,
			discard_id: discard.id,
			play_area_id: play_area.id,
			revealed_id: revealed.id,
			play_order: play_order)
		player.set_money(0)
		player.set_buys(1)
		player.set_actions(1)

	end

	def hook_reactions(type, player, card, events)
		puts "Reaction hook for #{type} when #{card.name} was played by #{player.name}"
		if type == :attack_played
			reaction_occurring = false
			logs_by_id = []
			players.each do |opponent|
				if opponent.id != player.id
					reaction_cards = []
					opponent.hand.cards.each do |card|
						if card.has_attr("is_reaction") and card.is_reaction == 1
							reaction_cards << card
						end
					end
					if reaction_cards.any?
						reaction_occurring = true
						state = {
							dialog_type: 'choose_cards',
							source: 'hand',
							count_type: 'at_most',
							count_value: 1,
							prompt: "Choose a reaction card"
						}
						dialog = Dialog.create(game: self, active_player: opponent, stage: 1, special_type: 'AvoidAttack', state: state.to_s)
						logs_by_id << {
							owner_id: opponent.id,
							id: dialog.id
						}.merge!(state)
					end
				end
			end
			if logs_by_id.any?
				events << {
					type: 'dialog',
					logs_by_id: logs_by_id
				}
			end
			return reaction_occurring
		end
		return false
	end

	def play_card(player, card, events)
		puts "#{player.name} play card #{card.name}"

		player.play_area.add_card(card)

    events << {
      type: "move_card",
      all_log: {
        from_player: player.name,
        from_zone: "hand",
        from_size: player.hand.cards.count,
        to_player: player.name,
        to_zone: "play_area",
        to_size: player.play_area.cards.count,
        to_card: card.view
      },
      player_log: { from_card: card.view }
    }

		push_card_state(player, card, 0)

		puts "Checking for reaction hooks"
		if card.is_true?('is_attack')
			if hook_reactions(:attack_played, player, card, events)
				puts "Reactions found - yielding for reaction dialog"
				return
			end
		end

		play_card_from_attribute(player, card, 0, events)

	end

	def play_card_from_attribute(player, card, next_attribute, events)
		puts "#{player.name} play card from attribute: #{card.name} @ #{next_attribute}"
		print_card_stack

		dirty_actions = dirty_money = dirty_buys = false
		pending_special = false
		card.card_attributes.where('attribute_order > ?', next_attribute).order(:attribute_order).each do |attr|
			puts "Playing card attribute for #{attr.key}"
			if (attr.key == 'is_action' and attr.value == 1)
				player.set_actions(player.actions - 1)
				dirty_actions = true
			elsif (attr.key == "money")
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
			elsif (attr.key =~ /^special_/)
				class_name = attr.key
				class_name.slice!('special_')
				pending_special = class_name.constantize.new()
				set_current_attribute(attr.attribute_order)
				break
			end
		end
		events << {
      type: "update_current_player",
			all_log: { key: "money", value: player.money }
		} if dirty_money
	  events << {
      type: "update_current_player",
			all_log: { key: "actions", value: player.actions }
		} if dirty_actions
		events << {
      type: "update_current_player",
			all_log: { key: "buys", value: player.buys }
		} if dirty_buys
		if pending_special
			pending_special.execute_from_game(self, player, events)
		else
			pop_card_state
			check_auto_advance(events)
		end
	end

	def buy_card(player, supply, events)
		puts "#{player.name} buy card: #{supply.name}"
		candidate_card = supply.card_pile.top_card
		if player.money >= candidate_card.cost and player.buys >= 1
			player.discard.add_card(candidate_card)
      newTop = supply.card_pile.top_card
			events << {
				type: "move_card",
        all_log: {
          from_player: "<system>",
          from_zone: "supply:#{supply.id}",
          from_size: supply.card_pile.cards.count,
          from_card: candidate_card.view,
          revealed: newTop && newTop.view,
          to_player: player.name,
          to_zone: "discard",
          to_size: player.discard.cards.count,
          to_card: candidate_card.view
        }
			}
			player.set_money(player.money - candidate_card.cost)
			events << {
        type: "update_current_player",
				all_log: { key: "money", value: player.money }
			} if candidate_card.cost > 0
			player.set_buys(player.buys - 1)
			events << {
        type: "update_current_player",
				all_log: {key: "buys", value: player.buys}
			}

			check_auto_advance(events)
		end
	end

	def setup_decks(events)
		puts "Setup decks"

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
			player.draw(5, events)
		end
	end

	def setup_supplies(events)
		puts "Setup supplies"

		add_supply('Copper', 'treasure', 10, events)
		add_supply('Silver', 'treasure', 10, events)
		add_supply('Gold', 'treasure', 10, events)

		add_supply('Estate', 'victory', 10, events)
		add_supply('Duchy', 'victory', 10, events)
		add_supply('Province', 'victory', 10, events)
		add_supply('Curse', 'victory', (players.count == 1) ? 10 : ((players.count - 1) * 10), events)

		setup_supplies_random(events)
	end

	def setup_supplies_random(events)

		add_supply('Chancellor', 'kingdom', 10, events)
	  CardTemplate.where.not(set: 'core').shuffle.take(9).collect{|template| template.name}.each do |card_name|
			add_supply(card_name, 'kingdom', 10, events)
		end

	end

	def add_supply(name, type, count, events)
		puts "Add supply #{name}"

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
    events << {
      type: "create_supply",
      all_log: {
        id: supply.id,
        top: card_pile.top_card.view,
				supply_type: supply.supply_type,
        size: count
      }
    }
	end

	def create_card(template_name)
		puts "Create card #{template_name}"

		card_template = CardTemplate.where(name: template_name).take()
		card = Card.create(
			card_template_id: card_template.id,
			game_id: id 
			);
		return card
	end

	def has_dialog()
		return dialogs.select{|d| d.stage > 0}.any?
	end

	def advance_phase(events)
		if (has_dialog)
			puts "(no - cannot advance due to dialog)"
			return
		end
		if phase == 'init'
			self.event_index = 0
      self.save

			setup_decks events
			setup_supplies events

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
		puts "Set phase to #{new_phase}"
		self.phase = new_phase
		events << {
      type: "phase_change",
      all_log: {
        new_phase: "#{phase}"
      }
		}
	end

	def check_auto_advance(events)
		puts "Checking for auto-advance"
		if self.phase == 'action'
			if current_player.actions == 0 or !current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_action" AND card_attributes.value == 1').exists?
				advance_phase(events)
			end
		elsif self.phase == 'treasure'
			unless current_player.hand.cards.joins(:card_attributes).where('card_attributes.key == "is_treasure" AND card_attributes.value == 1').exists?
				advance_phase(events)
			end
		elsif self.phase == 'buy'
			if current_player.buys == 0
				advance_phase(events)
			end
		elsif self.phase == 'cleanup'
			advance_phase(events)
		end

		unless self.phase == 'finished'
			check_victory(events)	
		end
	
	end

	def check_victory(events)
		puts "Checking for victory"
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

		if phase == 'finished'
			return false
		end

		return true
	end

	def do_cleanup(events)
		puts "Cleanup"

		player = current_player
		player.play_area.cards.each do |card|
			player.discard.add_card(card)
      events << {
        type: "move_card",
        all_log: {
          from_player: player.name,
          from_zone: 'play_area',
          from_size: player.play_area.cards.count,
          from_card: card.view,
          to_player: player.name,
          to_zone: 'discard',
          to_size: player.discard.cards.count,
          to_card: card.view
        }
      }
		end

		player.hand.cards.each do |card|
			player.discard.add_card(card)
      events << {
        type: "move_card",
        all_log: {
          from_player: player.name,
          from_zone: 'hand',
          from_size: player.hand.cards.count,
          from_card: card.view,
          to_player: player.name,
          to_zone: 'discard',
          to_size: player.discard.cards.count,
          to_card: card.view
        }
      }
		end
		player.draw(5, events)
		player.set_money(0)
		player.set_buys(1)
		player.set_actions(1)

		self.turn += 1
		events << {
			type: "update_current_player",
			all_log: {
				key: 'id',
				value: current_player.id
			}
		} << {
			type: "update_current_player",
			all_log: {
				key: 'name',
				value: current_player.name
			}
		} << {
			type: "update_current_player",
			all_log: {
				key: 'money',
				value: 0
			}
		} << {
			type: "update_current_player",
			all_log: {
				key: 'buys',
				value: 1
			}
		} << {
			type: "update_current_player",
			all_log: {
				key: 'actions',
				value: 1
			}
		}

	end

	def view_for(player)
		return :game => {
			supplies: supplies.collect{|supply|
				{
					id: supply.id,
					size: supply.cards.count,
					supply_type: supply.supply_type
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
					connected: opponent.connected
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
			dialogs: dialogs.select{|candidate| candidate.active_player == player and candidate.stage > 0}.collect{|dialog|
				{
					id: dialog.id
				}.merge!(eval(dialog.state))
			},
			phase: phase,
			turn: turn,
			event_index: event_index
		}
	end

end
