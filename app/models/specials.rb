class AttackDiscardTo

	def execute(game, player, events)
		logs_by_id = []
		game.players.select{|opponent| opponent.id != -1}.each do |opponent|
			total_cards = opponent.hand.cards.count()
			to_discard = total_cards - 3
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
