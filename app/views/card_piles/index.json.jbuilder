json.array!(@card_piles) do |card_pile|
  json.extract! card_pile, :id, :name
  json.url card_pile_url(card_pile, format: :json)
end
