json.array!(@supplies) do |supply|
  json.extract! supply, :id, :game_id, :supply_type, :card_pile_id
  json.url supply_url(supply, format: :json)
end
