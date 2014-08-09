json.array!(@player_attributes) do |player_attribute|
  json.extract! player_attribute, :id, :player, :key, :value
  json.url player_attribute_url(player_attribute, format: :json)
end
