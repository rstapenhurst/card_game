json.array!(@events) do |event|
  json.extract! event, :id, :game, :event_index, :event
  json.url event_url(event, format: :json)
end
