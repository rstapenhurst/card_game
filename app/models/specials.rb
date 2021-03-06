class Special

	def initialize
		@should_resume = false
	end

	def execute_from_game(game, player, events)
		puts "Special executing for #{player.name}"
		execute(game, player, events)
		if @should_resume
			puts "After execution, resuming card play"
			game.continue_card(events)
		else
			puts "Yield execution of card for special"
		end
	end

	def execute(game, player, events)
	end

	def process_response(game, player, dialog, data, events)
	end

	def react_to_attack(game, card, player, events)
		return true
	end

	def allow_reactions_from_player(game, player, events)
		puts "Checking whether #{player.name} will be attacked"
		should_attack = true
		player.revealed.cards.each do |card|
			card.card_attributes.each do |attr|
				if (attr.key =~ /^special_/)
					class_name = attr.key
					class_name.slice!('special_')
					special = class_name.constantize.new()
					should_attack &= special.react_to_attack(game, card, player, events)
					puts "After checking #{card.name}, #{player.name} should be attacked if #{should_attack}"
				end
			end
		end
		puts "#{player.name} will be attacked if #{should_attack}"
		return should_attack
	end

end

class GainCard < Special

	def gain_card(game, player, special_type, condition, events)
		puts "Building dialog for gaining a card"
		cards = []
		game.supplies.each do |supply|
			candidate_card = supply.card_pile.top_card
			if candidate_card == nil
				next
			end
			puts "Testing #{candidate_card.name}"
			if candidate_card != nil and condition.call(candidate_card)
				puts "#{candidate_card.name} is gainable"
				view = candidate_card.view
				view[:id] = supply.id
				cards << view
			else 
				puts "#{candidate_card.name} cannot be gained"
			end
		end

		if cards.any?
			state = {
				dialog_type: 'cardset_options',
				prompt: 'Choose a card to gain',
				cardsets: [
					{
						name: 'Options',
						id: 0,
						cards: cards,
						card_count_type: 'exactly',
						card_count_value: 1,
						options: {
							gain: "Gain",
						},
						option_count_type: 'exactly',
						option_count_value: 1
					}
				]
			}

			dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: special_type, state: state.to_s)
			game.dialogs << dialog

			events << {
				type: 'dialog',
				logs_by_id: [{
					owner_id: player.id,
					id: dialog.id
				}.merge(state)]
			}
			@should_resume = false
		else
			@should_resume = true
		end

	end

end

class Feast < GainCard

	def execute(game, player, events)
		puts "Executing Feast card"

		feast = game.current_state.card
		player.move_card_explicit_public(feast, player.name, 'play_area', player.play_area, '<system>', 'trash', game.trash, events)

		gain_card(game, player, 'Feast', Proc.new { |card| next card.cost <= 5 }, events)

	end

	def process_response(game, player, dialog, data, events)
		puts "Processing response for Feast. Data: #{data}"

		data['cardsets'].each do |cardset|
			supply = Supply.find(cardset['cards'][0])
			puts "Chose to gain from #{supply.name}"
			player.move_card_explicit_public(supply.card_pile.top_card, '<system>', supply.name, supply.card_pile, player.name, 'discard', player.discard, events)
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

		game.continue_card(events)

	end

end

class Chancellor < Special

	def execute(game, player, events)
		puts "Executing Chancellor card"

		state = {
			dialog_type: 'options',
			prompt: 'Chancellor - put deck into discard?',
			optionset: {
				option_count_type: 'exactly',
				option_count_value: 1,
				options: {
					yes: "Yes",
					no: "No"
				}
			}
		}

		dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Chancellor', state: state.to_s)
		game.dialogs << dialog

		events << {
			type: 'dialog',
			logs_by_id: [{
				owner_id: player.id,
				id: dialog.id
			}.merge(state)]
		}
		@should_resume = false

	end

	def process_response(game, player, dialog, data, events)
		puts "Processing response for Chancellor. Data: #{data}"

		data['optionset'].each do |decision|
			if decision == 'yes'
				puts "Decided to activate chancellor ability"
				player.deck.cards.each do |card|
					player.move_card_public(card, 'deck', 'discard', events)
				end
			else
				puts "Decided not to activate chancellor ability"
			end
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

		game.continue_card(events)

	end


end

class Library < Special

	def execute(game, player, events)
		puts "#{player.name} is executing Library"
		@should_resume = true

		while player.hand.cards.count < 7
			next_card = player.reveal_from_deck(events)
			if next_card.is_true?('is_action')
				puts "Action was drawn (#{next_card.name}). Sending dialog"

				state = {
					dialog_type: 'cardset_options',
					prompt: 'Library - action revealed',
					cardsets: [
						{
							name: next_card.name,
							id: next_card.id,
							cards: [next_card.view],
							card_count_type: 'exactly',
							card_count_value: 1,
							options: {
								draw: "Draw",
								set_aside: "Set aside"
							},
							option_count_type: 'exactly',
							option_count_value: 1
						}
					]
				}

				dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Library', state: state.to_s)
				game.dialogs << dialog

				events << {
					type: 'dialog',
					logs_by_id: [{
						owner_id: player.id,
						id: dialog.id
					}.merge(state)]
				}
				@should_resume = false
				break
			else
				puts "Non-Action was drawn (#{next_card.name}). Moving to hand"
				player.move_card_public(next_card, 'revealed', 'hand', events)
			end

		end

		if @should_resume
			player.revealed.cards.each do |card|
				player.move_card_public(card, 'revealed', 'discard', events)
			end
		end
	end

	def process_response(game, player, dialog, data, events)

		data['cardsets'].each do |cardset|
			card = Card.find(cardset['id'])
			option = cardset['options'][0]
			if option == 'draw'
				puts "Chose to draw action"
			  player.move_card_from_source_public(card, 'hand', events)
			elsif option == 'set_aside'
				puts "Chose to set action aside. Leaving in revealed pile."
			end
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

		execute_from_game(game, player, events)
	end

end

class Spy < Special

	def execute(game, player, events)
		puts "Execute spy for #{player.name}"

		cardsets = []
		game.players.each do |opponent|
			unless allow_reactions_from_player(game, opponent, events)
				next
			end

			revealed_card = opponent.reveal_from_deck(events)
			if revealed_card != nil
				puts "#{opponent.name} has revealed #{revealed_card.name} for Spy"
				cardsets << {
					name: opponent.name,
					id: opponent.id,
					cards: [revealed_card.view],
					card_count_type: 'exactly',
					card_count_value: 1,
					options: {
						discard: "Discard",
						deck: "Return to deck",
					},
					option_count_type: 'exactly',
					option_count_value: 1
				}
			else
				puts "#{opponent.name} has no card to reveal for Spy"
			end
		end

		if cardsets.any?
			puts "Sending Spy dialog"
			state = {
				dialog_type: 'cardset_options',
				prompt: 'Choose actions for spy attacks',
				cardsets: cardsets
			}

			dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Spy', state: state.to_s)
			game << dialog

			events << {
				type: 'dialog',
				logs_by_id: [{
					owner_id: player.id,
					id: dialog.id
				}.merge(state)]
			}
		else
			puts "No dialog for spy - resuming card play"
			@should_resume = true
		end
	end

	def process_response(game, player, dialog, data, events)
		puts "Process response spy #{player.name} with data #{data}"

		data['cardsets'].each do |cardset|
			opponent = Player.find(cardset['id'])
			card = Card.find(cardset['cards'][0])
			option = cardset['options'][0]
			if option == 'discard'
				opponent.move_card_from_source_public(card, 'discard', events)
			elsif option == 'deck'
				opponent.move_card_explicit_public(card, opponent.name, 'revealed', opponent.revealed, opponent.name, 'deck', opponent.deck, events)
			end
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

		game.continue_card(events)

	end

end

class Thief < Special

	def execute(game, player, events)
		puts "Execute thief for #{player.name}"

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
					id: opponent.id,
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
			puts "Sending dialog for Thief"
			state = {
				dialog_type: 'cardset_options',
				prompt: 'Choose actions for thief attacks',
				cardsets: cardsets
			}

			dialog = Dialog.create(game: game, active_player: player, stage: 1, special_type: 'Thief', state: state.to_s)
			game << dialog

			events << {
				type: 'dialog',
				logs_by_id: [{
					owner_id: player.id,
					id: dialog.id
				}.merge(state)]
			}
		else
			puts "Nothing to thieve - continue card play"
			game.players.each do |opponent|
				opponent.revealed.cards.each do |card|
					opponent.move_card_public(card, 'revealed', 'discard', events)
				end
			end
			@should_resume = true
		end

	end

	def process_response(game, player, dialog, data, events)

		data['cardsets'].each do |cardset|
			opponent = Player.find(cardset['id'])
			card = Card.find(cardset['cards'][0])
			option = cardset['options'][0]
			if option == 'discard'
				opponent.move_card_from_source_public(card, 'discard', events)
			elsif option == 'trash'
				opponent.move_card_explicit_public(card, opponent.name, 'revealed', opponent.revealed, '<system>', 'trash', game.trash, events)
			elsif option == 'gain'
				opponent.move_card_explicit_public(card, opponent.name, 'revealed', opponent.revealed, '<system>', 'trash', game.trash, events)
				player.move_card_explicit_public(card, '<system>', 'trash', game.trash, player.name, 'discard', player.discard, events)
			end
		end

		game.players.each do |opponent|
			opponent.revealed.cards.each do |card|
				opponent.move_card_public(card, 'revealed', 'discard', events)
			end
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

		game.continue_card(events)

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
			game.dialogs << dialog

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
		else
			@should_resume = true
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

		if !game.has_dialog
			game.continue_card(events)
		end
	end

end

class AvoidAttack < Special

	def execute(game, player, events)
		@should_resume = true
	end

	def process_response(game, player, dialog, data, events)
		puts "Processing #{player.name}'s dialog response: #{data}"

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
			game.continue_card(events)
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
		@should_resume = true

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
		@should_resume = true
	end
end

class CouncilRoom < Special

	def execute(game, player, events)
		game.players.each do |opponent|
			if opponent.id != player.id
				opponent.draw(1, events)
			end
		end
		@should_resume = true
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
		game.dialogs << dialog

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

		game.continue_card(events)
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
			game.dialogs << dialog

			logs_by_id << {
				owner_id: opponent.id,
				id: dialog.id
			}.merge!(state)
		end

		if logs_by_id.any?
			events << {
				type: 'dialog',
				logs_by_id: logs_by_id
			}
		else
			@should_resume = true
		end

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

		if !game.has_dialog
			game.continue_card(events)
		end

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
		game.dialogs << dialog

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

		game.continue_card(events)

	end

end
