# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

def make_card(name, set, cost, attribs)
	template = CardTemplate.create(name: name, set: set)

	attribs[:is_treasure] ||= 0
	attribs[:is_victory] ||= 0
	attribs[:is_action] ||= 0
	attribs[:is_attack] ||= 0

	CardAttribute.create(card_template: template, key: :cost, value: cost)

	attribs.each do |key,value| 
		CardAttribute.create(card_template: template, key: key, value: value)
	end

end

make_card("Province", "base", 8, { is_victory: 1, victory_points: 6})
make_card("Duchy", "base", 5, { is_victory: 1, victory_points: 3})
make_card("Estate", "base", 2, { is_victory: 1, victory_points: 1})
make_card("Curse", "base", 0, { victory_points: -1 })
	
make_card("Copper", "base", 0, { is_treasure: 1, money: 1})
make_card("Silver", "base", 3,{  is_treasure: 1, money: 2})
make_card("Gold", "base", 6, { is_treasure: 1, money: 3})

make_card("Village", "base", 3, { is_action: 1, cards: 1, actions: 2})
make_card("Smithy", "base", 4, { is_action: 1, cards: 3})
make_card("Laboratory", "base", 5, { is_action: 1, cards: 2, actions: 1})
make_card("Market", "base", 5, { is_action: 1, cards: 1, actions: 1, money: 1, buys: 1})
make_card("Festival", "base", 5, { is_action: 1, actions: 2, money: 2, buys: 1})
make_card("Woodcutter", "base", 3, { is_action: 1, buys: 1, money: 2})

make_card("Cellar", "base", 2, { is_action: 1, actions: 1, special_Cellar: 0})
make_card("Militia", "base", 4, { is_action: 1, is_attack: 1, money: 2, special_AttackDiscardTo: 3})
make_card("Chapel", "base", 2, { is_action: 1, special_YouMayTrash: 4})
make_card("Council Room", "base", 5, { is_action: 1, cards: 4, buys: 1, special_CouncilRoom: 1})
make_card("Witch", "base", 5, { is_action: 1, is_attack: 1, cards: 2, special_Curse: 1})
make_card("Adventurer", "base", 6, { is_action: 1, special_Adventurer: 2})
make_card("Moat", "base", 2, { is_action: 1, is_reaction: 1, cards: 2, special_AvoidAttack: 1})
make_card("Bureaucrat", "base", 4, { is_action: 1, is_attack: 1, special_Bureaucrat: 1})

make_card("Great Hall", "intrigue", 3, { is_action: 1, is_victory: 1, cards: 1, actions: 1, victory_points: 1 })
