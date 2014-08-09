json.array!(@games) do |game|
  json.extract! game, :id, :name, :phase, :turn
  json.url game_url(game, format: :json)
end
