



declare class Channel {
  bind(eventName: string, callback: Function);
}

declare class WebSocketRails {
  constructor(url: string, useWebSockets: boolean);
  subscribe(channel: string) : Channel;
  trigger(eventName: string, eventData: string);
}

declare class Card {
  id: number;
  cost: number;
  money: number;
  victory_points: number;
  actions: number;
  buys: number;
  cards: number;

  name: string;
  template_name: string;

  is_action: boolean;
  is_treasure: boolean;
  is_victory: boolean;

  marked: boolean;
}

declare class FaceUpPile {
  id: number;
  size: number;
  top: Card;
  name: string;
  supply_type: string;
}

declare class You {
  name: string;
  deck_size: number;
  hand: Array<Card>;
  discard: FaceUpPile;
}

declare class Opponent {
  name: string;
  deck_size: number;
  hand_size: number;
  discard: FaceUpPile;
  connected: boolean;
}

declare class Player {
  name: string;

  money: number;
  actions: number;
  buys: number;
}

declare class GameState {
  phase: string;
  current_player: Player;
  player: You;
  opponents: Array<Opponent>;
  play_area: Array<Card>;
  supplies: Array<FaceUpPile>;
  dialogs: Array<any>;
}

declare class CardsetOption {
  card_count_type: string;
  card_count_value: number;

  option_count_type: string;
  option_count_value: number;

  name: string;

  id: number;

  cards: Array<Card>;

  options: any;

  cardsResult: any;
  optionsResult: any;
}

declare class ChooseCards extends Events.EventBase {
  player_log: {
    id: number;
    dialog_type: string;
    source: string;
    count_type: string;
    count_value: number;
    prompt: string;
  }
}

declare module Events {
  class EventBase {
    event_index: number;
    find(key:string) : Maybe;
    get(key:string) : any;
  }

  class Maybe {
    scope: string;
    value: any;
  }
}

interface Markable {
  id: number;
  marked: boolean;
}

declare class OptionSet {
  option_count_type: string;
  option_count_value: number;
  options: any;
  optionsResult: any;
}

