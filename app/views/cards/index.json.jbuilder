json.array!(@cards) do |card|
  json.extract! card, :id, :card_template_id
  json.url card_url(card, format: :json)
end
