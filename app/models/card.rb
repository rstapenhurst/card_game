class Card < ActiveRecord::Base
  belongs_to :card_template
	has_many :card_attributes, through: :card_template
	belongs_to :game
	has_one :pile
	has_one :card_pile, through: :pile

	def name
		return "#{card_template.name}(#{id})"
	end

	def method_missing(meth, *args, &block)
		attribute = card_attributes.where(key: meth).take
		if attribute
			return attribute.value
		else
			return super
		end
	end

	def has_attr(attr)
		card_attributes.where(key: attr).count > 0
	end

	def is_true?(attr)
		has_attr(attr) and self.send(attr) == 1
	end

	def view
		return card_attributes.collect{|att|
				[att.key, att.value]
			}.to_h.merge({
				name: name,
				id: id,
				template_name: card_template.name
			})
	end
end
