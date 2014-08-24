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

	CardAttribute.create(card_template: template, key: :cost, value: cost, attribute_order: 1)

	attribs.each_with_index do |attrib, index| 
		CardAttribute.create(card_template: template, key: attrib[0], value: attrib[1], attribute_order: index+2)
	end
end

class CardAttribBuilder 

	def initialize
		@attrib_list = []
		@missing = { is_victory: true, is_treasure: true, is_action: true, is_attack: true }
	end

	def victory(points)
		if @missing[:is_victory]
			@attrib_list << [:is_victory, 1]
			@missing[:is_victory] = false
		end
		@attrib_list << [:victory_points, points]
		return self
	end

	def treasure(points)
		if @missing[:is_treasure]
			@attrib_list << [:is_treasure, 1]
			@missing[:is_treasure] = false
		end
		@attrib_list << [:money, points]
		return self
	end

	def money(points)
		@attrib_list << [:money, points]
		return self
	end

	def cards(points)
		if @missing[:is_action]
			@attrib_list << [:is_action, 1]
			@missing[:is_action] = false
		end
		@attrib_list << [:cards, points]
		return self
	end

	def buys(value)
		@attrib_list << [:buys, value]
		return self
	end

	def actions(points)
		if @missing[:is_action]
			@attrib_list << [:is_action, 1]
			@missing[:is_action] = false
		end
		@attrib_list << [:actions, points]
		return self
	end

	def reaction
		@attrib_list << [:is_reaction, 1]
		return self
	end

	def attack
		if @missing[:is_attack]
			@attrib_list << [:is_attack, 1 ]
			@missing[:is_attack] = false
		end
		return self
		
	end

	def action
		if @missing[:is_action]
			@attrib_list << [:is_action, 1 ]
			@missing[:is_action] = false
		end
		return self
	end

	def special(name, value)
		@attrib_list << ["special_#{name}", value]
		return self
	end

	def go
		@missing.each do |k,v|
			if v
				@attrib_list.unshift [k, 0]
			end
		end
		return @attrib_list
	end

end

def attribs
	return CardAttribBuilder.new
end


make_card("Province", "base", 8, attribs.victory(6).go)
make_card("Duchy", "base", 5, attribs.victory(3).go)
make_card("Estate", "base", 2, attribs.victory(1).go)
make_card("Curse", "base", 0, attribs.victory(-1).go)
	
make_card("Copper", "base", 0, attribs.treasure(1).go)
make_card("Silver", "base", 3, attribs.treasure(2).go)
make_card("Gold", "base", 6, attribs.treasure(3).go)

make_card("Village", "base", 3, attribs.cards(1).actions(2).go)
make_card("Smithy", "base", 4, attribs.cards(3).go)
make_card("Laboratory", "base", 5, attribs.cards(2).actions(1).go)
make_card("Market", "base", 5, attribs.cards(1).actions(1).money(1).buys(1).go)
make_card("Festival", "base", 5, attribs.actions(2).money(2).buys(1).go)
make_card("Woodcutter", "base", 3, attribs.buys(1).money(2).go)

make_card("Cellar", "base", 2, attribs.actions(1).special('Cellar', 0).go)
make_card("Militia", "base", 4, attribs.action.attack.money(2).special('AttackDiscardTo', 3).go)

make_card("Chapel", "base", 2, attribs.action.special('YouMayTrash', 4).go)
make_card("Council Room", "base", 5, attribs.cards(4).buys(1).special('CouncilRoom', 1).go)
make_card("Witch", "base", 5, attribs.attack.cards(2).special('Curse', 1).go)
make_card("Adventurer", "base", 6, attribs.action.special('Adventurer', 2).go)
make_card("Moat", "base", 2, attribs.reaction.cards(2).special('AvoidAttack', 1).go)
make_card("Bureaucrat", "base", 4, attribs.action.attack.special('Bureaucrat', 1).go)
make_card("Thief", "base", 4, attribs.action.attack.special('Thief', 2).go)
make_card("Spy", "base", 4, attribs.attack.cards(1).actions(1).special('Spy', 1).go)
make_card("Library", "base", 5, attribs.action.special('Library', 7).go)

make_card("Great Hall", "intrigue", 3, attribs.victory(1).cards(1).actions(1).go)

User.create({name: 'tubs', password: 'test', password_confirmation: 'test'})
User.create({name: 'qwe', password: 'qwe', password_confirmation: 'qwe'})
User.create({name: 'asd', password: 'asd', password_confirmation: 'asd'})
