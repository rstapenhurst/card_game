json.array!(@players) do |player|
  json.extract! player, :id, :game_id, :user_id, :play_order, :deck, :hand, :play_area, :discard
  json.url player_url(player, format: :json)
end
