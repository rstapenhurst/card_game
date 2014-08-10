WebsocketRails::EventMap.describe do
	subscribe :card_play_event, to: NoobController, with_method: :play_card
	subscribe :phase_advance_event, to: NoobController, with_method: :advance_phase
	subscribe :game_fetch_event, to: NoobController, with_method: :game_fetch
end
