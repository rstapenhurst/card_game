WebsocketRails::EventMap.describe do
	subscribe :noob_event, to: NoobController, with_method: :noob_event
	subscribe :card_play_event, to: NoobController, with_method: :play_card
end
