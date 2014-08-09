json.array!(@piles) do |pile|
  json.extract! pile, :id, :card_pile_id, :card_id, :card_order
  json.url pile_url(pile, format: :json)
end
