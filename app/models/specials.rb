class Adventurer
	def execute(game, player, events)
		count = 0
		while count < 2
			if player.deck.is_empty
				if (player.discard.is_empty)
					break
				end
				player.discard.cards.each do |card|
					player.deck.add_card(card)
				end
				events << {
          type: 'recycle_deck',
					all_log: {
            player: player.name,
            size: player.deck.cards.count
          }
				} 
				player.deck.shuffle
			end
			next_card = player.deck.top_card
			if next_card.has_attr("is_treasure") and next_card.is_treasure == 1
				puts "#{next_card.name} is a treasure"
				player.hand.add_card(next_card)
				new_top = player.deck.top_card
				events << {
					type: "move_card",
					all_log: {
						from_player: player.id,
						from_zone: "deck",
						from_size: player.deck.cards.count,
						from_card: next_card.view,
						revealed: new_top && new_top.view,
						to_player: player.id,
						to_zone: "hand",
						to_size: player.hand.cards.count,
						to_card: next_card.view
					}
				}
				count += 1
			else
				puts "#{next_card.name} is a noob card"
				player.revealed.add_card(next_card)
				new_top = player.deck.top_card
				events << {
					type: "move_card",
					all_log: {
						from_player: player.id,
						from_zone: "deck",
						from_size: player.deck.cards.count,
						from_card: next_card.view,
						revealed: new_top && new_top.view,
						to_player: player.id,
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
					from_player: player.id,
					from_zone: "revealed",
					from_size: player.revealed.cards.count,
					from_card: card.view,
					revealed: new_top && new_top.view,
					to_player: player.id,
					to_zone: "discard",
					to_size: player.discard.cards.count,
					to_card: card.view
				}
			}
		end

	end

end


class Curse
	def execute(game, player, events)
		curse_pile = game.supplies.select{|supply| supply.name == "Curse"}[0]
		game.players.each do |opponent|
			if opponent.id != player.id
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

class CouncilRoom

	def execute(game, player, events)
		game.players.each do |opponent|
			if opponent.id != player.id
				opponent.draw(1, events)
			end
		end
	end

end

class YouMayTrash

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
					to_player: player.name,
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


class AttackDiscardTo

	def execute(game, player, events)
		logs_by_id = []
		game.players.select{|opponent| opponent.id != player.id}.each do |opponent|
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

class Cellar

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
