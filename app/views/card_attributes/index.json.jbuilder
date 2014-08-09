json.array!(@card_attributes) do |card_attribute|
  json.extract! card_attribute, :id, :card_template_id, :attribute, :value, :attribute_order
  json.url card_attribute_url(card_attribute, format: :json)
end
