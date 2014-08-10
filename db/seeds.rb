# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

def make_card(name, cost, attribs)
	template = CardTemplate.create(name: name)

	attribs[:is_treasure] ||= 0
	attribs[:is_victory] ||= 0
	attribs[:is_action] ||= 0

	CardAttribute.create(card_template: template, key: :cost, value: cost)

	attribs.each do |key,value| 
		CardAttribute.create(card_template: template, key: key, value: value)
	end

end

make_card("Province", 8, { is_victory: 1, victory_points: 6})
make_card("Duchy", 5, { is_victory: 1, victory_points: 3})
make_card("Estate", 2, { is_victory: 1, victory_points: 1})
	
make_card("Copper", 0, { is_treasure: 1, money: 1})
make_card("Silver", 3,{  is_treasure: 1, money: 2})
make_card("Gold", 6, { is_treasure: 1, money: 3})

make_card("Village", 3, { is_action: 1, cards: 1, actions: 2})
make_card("Smithy", 4, { is_action: 1, cards: 3})
make_card("Laboratory", 5, { is_action: 1, cards: 2, actions: 1})
make_card("Market", 5, { is_action: 1, cards: 1, actions: 1, money: 1, buys: 1})
make_card("Festival", 5, { is_action: 1, actions: 2, money: 2, buys: 1})

User.create(name: "tubs")
User.create(name: "richante")
User.create(name: "shosh")
