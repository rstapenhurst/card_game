class Special

	def execute(game, player, events)
	end

	def process_response(game, player, dialog, data, events)
	end

	def react_to_attack(game, card, player, events)
		return true
	end

	def allow_reactions_from_player(game, player, events)
		should_attack = true
		player.revealed.cards.each do |card|
			card.card_attributes.each do |attr|
				if (attr.key =~ /^special_/)
					class_name = attr.key
					class_name.slice!('special_')
					special = class_name.constantize.new()
					should_attack &= special.react_to_attack(game, card, player, events)
				end
			end
		end
		return should_attack
	end
end

class Thief < Special

	def execute(game, player, events)
		cardsets = []
		game.players.select{|opponent| opponent.id != player.id}.each do |opponent|
			unless allow_reactions_from_player(game, opponent, events)
				next
			end

			revealed_cards = [opponent.reveal_from_deck(events), opponent.reveal_from_deck(events)]
			revealed_treasure_cards = revealed_cards.select{|card| card.is_true?('is_treasure')}.map{|card| card.view}
			if revealed_treasure_cards.any?
				cardsets << {
					name: opponent.name,
					cards: revealed_treasure_cards,
					card_count_type: 'exactly',
					card_count_value: 1,
					options: {
						discard: "Discard",
						trash: "Trash",
						gain: "Trash and gain"
					},
					option_count_type: 'exactly',
					option_count_value: 1
				}
			end
		end

		if cardsets.any?
			state = {
				dialog_type: 'cardset_options',
				cardsets: cardsets
			}

			dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Thief', state: state.to_s)

			events << {
				type: 'dialog',
				logs_by_id: [{
					owner_id: player.id,
					id: dialog.id
				}.merge(state)]
			}
		end

	end

	def process_response(game, player, dialog, data, events)
	end

end

class Bureaucrat < Special

	def execute(game, player, events)
		logs_by_id = []
		game.players.select{|opponent| opponent.id != player.id}.each do |opponent|
			should_attack = allow_reactions_from_player(game, opponent, events)
			unless should_attack
				next
			end
			unless opponent.hand.has_card_boolean?('is_victory')
				next	
			end
			state = {
				dialog_type: 'choose_cards',
				source: 'hand',
				count_type: 'exactly',
				count_value: 1,
				prompt: "Choose a victory to place on top of your deck"
			}
			dialog = Dialog.create(game: game, active_player: opponent, stage: 1, special_type: 'Bureaucrat', state: state.to_s)

			logs_by_id << {
				owner_id: opponent.id,
				id: dialog.id
			}.merge!(state)
		end

		events << {
			type: 'dialog',
			logs_by_id: logs_by_id
		}

		supply = game.supplies.joins(:card_pile).where('card_piles.name' => 'Silver').take

		unless supply.card_pile.is_empty
			candidate_card = supply.card_pile.top_card
			player.deck.add_card(candidate_card)
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
					to_zone: "deck",
					to_size: player.deck.cards.count,
					to_card: candidate_card.view
				}
			}
		end

	end

	def process_response(game, player, dialog, data, events)
		data['cards'].each do |card_id|
			card = Card.find(card_id)
			if player.hand.cards.where(id: card.id).count == 0
				return
			end
			player.deck.add_card(card)
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "hand",
					from_size: player.hand.cards.count,
					to_player: player.name,
					to_zone: "deck",
					to_size: player.discard.cards.count,
					to_card: card.view
				},
				player_log: { from_card: card.view }
			}
		end

		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id,
				dialog_type: 'complete'
			}
		}
		dialog.stage = 0
		dialog.save
	end

end

class AvoidAttack < Special

	def execute(game, player, events)
	end

	def process_response(game, player, dialog, data, events)

		card_count = 0
		data['cards'].each do |card_id|
			card = Card.find(card_id)
			if player.hand.cards.where(id: card.id).count == 0
				return
			end
			card_count += 1
			player.revealed.add_card(card)
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "hand",
					from_size: player.hand.cards.count,
					to_player: player.name,
					to_zone: "revealed",
					to_size: player.revealed.cards.count,
					to_card: card.view
				},
				player_log: { from_card: card.view }
			}
		end

		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id,
				dialog_type: 'complete'
			}
		}
		dialog.stage = 0
		dialog.save

		if !game.has_dialog
			game.apply_card_actions(game.current_player, game.current_player.play_area.top_card, events)
		end

	end

	def react_to_attack(game, card, player, events)
		player.hand.add_card(card)
		events << {
			type: "move_card",
			all_log: {
				from_player: player.name,
				from_zone: "reavealed",
				from_size: player.revealed.cards.count,
				from_card: card.view,
				to_player: player.name,
				to_zone: "hand",
				to_size: player.hand.cards.count,
				to_card: card.view
			}
		}
		return false
	end

end

class Adventurer < Special
	def execute(game, player, events)
		count = 0
		while count < 2
			player.predraw(events)
			if player.deck.is_empty
				break
			end
			next_card = player.deck.top_card
			if next_card.has_attr("is_treasure") and next_card.is_treasure == 1
				player.hand.add_card(next_card)
				new_top = player.deck.top_card
				events << {
					type: "move_card",
					all_log: {
						from_player: player.name,
						from_zone: "deck",
						from_size: player.deck.cards.count,
						from_card: next_card.view,
						revealed: new_top && new_top.view,
						to_player: player.name,
						to_zone: "hand",
						to_size: player.hand.cards.count,
						to_card: next_card.view
					}
				}
				count += 1
			else
				player.revealed.add_card(next_card)
				new_top = player.deck.top_card
				events << {
					type: "move_card",
					all_log: {
						from_player: player.name,
						from_zone: "deck",
						from_size: player.deck.cards.count,
						from_card: next_card.view,
						revealed: new_top && new_top.view,
						to_player: player.name,
						to_zone: "revealed",
						to_size: player.revealed.cards.count,
						to_card: next_card.view
					}
				}
			end
		end
		player.revealed.cards.each do |card|
			player.discard.add_card(card)
			new_top = player.revealed.top_card
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "revealed",
					from_size: player.revealed.cards.count,
					from_card: card.view,
					revealed: new_top && new_top.view,
					to_player: player.name,
					to_zone: "discard",
					to_size: player.discard.cards.count,
					to_card: card.view
				}
			}
		end

	end

end


class Curse < Special
	def execute(game, player, events)
		game.supplies.map{|x| x}
		game.players.each do |opponent|
			if opponent.id != player.id
				should_attack = allow_reactions_from_player(game, opponent, events)
				unless should_attack
					next
				end
				curse = curse_pile.card_pile.top_card
				opponent.discard.add_card(curse)
				newTop = curse_pile.card_pile.top_card 
				events << {
					type: "move_card",
					all_log: {
						from_player: "<system>",
						from_zone: "supply:#{curse_pile.id}",
						from_size: curse_pile.card_pile.cards.count,
						from_card: curse.view,
						revealed: newTop && newTop.view,
						to_player: opponent.name,
						to_zone: "discard",
						to_size: opponent.discard.cards.count,
						to_card: curse.view
					}
				}
			end
		end
	end
end

class CouncilRoom < Special

	def execute(game, player, events)
		game.players.each do |opponent|
			if opponent.id != player.id
				opponent.draw(1, events)
			end
		end
	end

end

class YouMayTrash < Special

	def execute(game, player, events)
		state = {
			dialog_type: 'choose_cards',
			source: 'hand',
			count_type: 'at_most',
			count_value: 4,
			prompt: "Trash up to 4 cards"
		}
		dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'YouMayTrash', state: state.to_s)
		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id
			}.merge!(state)
		}

	end

	def process_response(game, player, dialog, data, events)

		if data['cards'].count > 4
			return
		end
		data['cards'].each do |card_id|
			card = Card.find(card_id)
			if player.hand.cards.where(id: card.id).count == 0
				return
			end
			game.trash.add_card(card)
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "hand",
					from_size: player.hand.cards.count,
					to_player: "<system>",
					to_zone: "trash",
					to_size: game.trash.cards.count,
					to_card: card.view
				},
				player_log: { from_card: card.view }
			}
		end

		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id,
				dialog_type: 'complete'
			}
		}
		dialog.stage = 0
		dialog.save
	end

end


class AttackDiscardTo < Special

	def execute(game, player, events)
		logs_by_id = []
		game.players.select{|opponent| opponent.id != player.id}.each do |opponent|
			should_attack = allow_reactions_from_player(game, opponent, events)
			unless should_attack
				next
			end
			total_cards = opponent.hand.cards.count()
			to_discard = total_cards - 3
			if to_discard <= 0
				next	
			end
			state = {
				dialog_type: 'choose_cards',
				source: 'hand',
				count_type: 'exactly',
				count_value: to_discard,
				prompt: "Discard down to 3 cards"
			}
			dialog = Dialog.create(game: game, active_player: opponent, stage: 1, special_type: 'AttackDiscardTo', state: state.to_s)

			logs_by_id << {
				owner_id: opponent.id,
				id: dialog.id
			}.merge!(state)
		end

		events << {
			type: 'dialog',
			logs_by_id: logs_by_id
		}

	end

	def process_response(game, player, dialog, data, events)
		data['cards'].each do |card_id|
			card = Card.find(card_id)
			if player.hand.cards.where(id: card.id).count == 0
				return
			end
			player.discard.add_card(card)
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "hand",
					from_size: player.hand.cards.count,
					to_player: player.name,
					to_zone: "discard",
					to_size: player.discard.cards.count,
					to_card: card.view
				},
				player_log: { from_card: card.view }
			}
		end

		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id,
				dialog_type: 'complete'
			}
		}
		dialog.stage = 0
		dialog.save
	end

end

class Cellar < Special

	def execute(game, player, events)
		state = {
			dialog_type: 'choose_cards',
			source: 'hand',
			count_type: 'at_least',
			count_value: 0,
			prompt: "Discard any number of cards"
		}
		dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Cellar', state: state.to_s)
		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id
			}.merge!(state)
		}
	end

	def process_response(game, player, dialog, data, events)

		card_count = 0
		data['cards'].each do |card_id|
			card = Card.find(card_id)
			if player.hand.cards.where(id: card.id).count == 0
				return
			end
			card_count += 1
			player.discard.add_card(card)
			events << {
				type: "move_card",
				all_log: {
					from_player: player.name,
					from_zone: "hand",
					from_size: player.hand.cards.count,
					to_player: player.name,
					to_zone: "discard",
					to_size: player.discard.cards.count,
					to_card: card.view
				},
				player_log: { from_card: card.view }
			}
		end
		player.draw(card_count, events)

		events << {
			type: 'dialog',
			player_log: {
				id: dialog.id,
				dialog_type: 'complete'
			}
		}
		dialog.stage = 0
		dialog.save

	end

end
