WebsocketRails::EventMap.describe do
	subscribe :card_play_event, to: NoobController, with_method: :play_card
	subscribe :card_buy_event, to: NoobController, with_method: :buy_card
	subscribe :dialog_respond_event, to: NoobController, with_method: :respond_dialog
	subscribe :phase_advance_event, to: NoobController, with_method: :advance_phase
	subscribe :game_fetch_event, to: NoobController, with_method: :game_fetch
  subscribe :chat_event, to: NoobController, with_method: :chat
end
