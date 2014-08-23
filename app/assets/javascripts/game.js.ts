
/// <reference path="phaser.d.ts" />
/// <reference path="jquery.d.ts" />

declare class Channel {
  bind(eventName: string, callback: Function);
}

declare class WebSocketRails {
  constructor(url: string, useWebSockets: boolean);
  subscribe(channel: string) : Channel;
  trigger(eventName: string, eventData: string);
}

class Card {
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

module Events {

  var outstanding_log: Array<string> = [];

  export function event(raw: any) {
    raw.get = function(key) {
      if (raw.hasOwnProperty('all_log') && raw.all_log.hasOwnProperty(key))
        return raw.all_log[key]
      if (raw.hasOwnProperty('opponent_log') && raw.opponent_log.hasOwnProperty(key))
        return raw.opponent_log[key]
      if (raw.hasOwnProperty('player_log') && raw.player_log.hasOwnProperty(key))
        return raw.player_log[key]
      if (raw.hasOwnProperty('log_by_id') && raw.log_by_id.hasOwnProperty(key))
        return raw.log_by_id[key]
    };
    raw.find = function(key) {
      if (raw.hasOwnProperty('all_log') && raw.all_log.hasOwnProperty(key))
        return {value: raw.all_log[key], scope: "all"};
      if (raw.hasOwnProperty('opponent_log') && raw.opponent_log.hasOwnProperty(key))
        return {value: raw.opponent_log[key], scope: "opponent"};
      if (raw.hasOwnProperty('player_log') && raw.player_log.hasOwnProperty(key))
        return {value: raw.player_log[key], scope: "player"};
      if (raw.hasOwnProperty('log_by_id') && raw.log_by_id.hasOwnProperty(key))
        return {value: raw.log_by_id[key], scope: "log_by_id"};
    };
  }

  export function handle(state: ClientState, raw) {

    event(raw);

    switch (raw.type) {
      case 'phase_change':
        handlePhaseChange(state, <PhaseChange>raw);
        break;
      case 'create_supply':
        handleCreateSupply(state, <CreateSupply>raw);
        break;
      case 'move_card':
        handleMoveCard(state, <MoveCard>raw);
        break;
      case 'dialog':
        switch (raw.get('dialog_type')) {
          case 'complete':
            state.setInstructions('');
            state.setFunctions(null, null);
            break;
          default:
            state.handleDialog(raw);
            break;
        }
        break;
      case 'recycle_deck':
        state.recycleDeck(raw.all_log.player, raw.all_log.size);
        log(null, 'card_recycle', '<strong>' + raw.all_log.player + '</strong>');
        break;
      case 'update_current_player':
        handleUpdateCurrentPlayer(state, <UpdatePlayer>raw);
        break;
			case 'player_connected':
				state.playerConnected(raw.all_log.name, true);
				log(null, null, '<strong>' + raw.all_log.name + ' connected</strong>');
				break;
			case 'player_disconnected':
				state.playerConnected(raw.all_log.name, false);
				log(null, null, '<strong>' + raw.all_log.name + ' disconnected</strong>');
				break;
      default:
        log(null, null, JSON.stringify(raw));
        break;
    }
  }

  function log(event: EventBase, img: string, message: string) {
    var build = "<div class=\"log-line\">";

    if (event) {
      build += "[" + event.event_index + "] "
    }

    if (img) {
      build += "<img class=\"log-icon\" src=\"/assets/log_" + img + ".png\">";
    }

    build += "<span class=\"log-text\">" + message + "</span>";

    build += "</div>";

    outstanding_log.push(build);
  }

  export declare class ChooseCards extends EventBase {
    player_log: {
      id: number;
      dialog_type: string;
      source: string;
      count_type: string;
      count_value: number;
      prompt: string;
    }
  }




  declare class CreateSupply extends EventBase {
    all_log: FaceUpPile;
  }

  function handleCreateSupply(state: ClientState, event: CreateSupply) {
    log(event, null, "Create supply [" + event.all_log.top.template_name + "], size: " + event.all_log.size);
    state.createSupply(event.all_log);
  }

  declare class UpdatePlayer extends EventBase {
    all_log: {
      key: string;
      value: any;
    }
  }

  export function flushLog(state: ClientState) {
  if (!state || (state.gameState.phase != "treasure") || currentLogType != "card_play") {
    if (currentLog.length) {
      log(null, currentLogType, currentLog);
    }
    currentLogType = null;
    currentLog = "";
	}
    outstanding_log.forEach(function(line) {
      $("#game-log").prepend(line);
    });
    outstanding_log = [];
  }


  var newMoney: number = null;

  function handleUpdateCurrentPlayer(state: ClientState, event: UpdatePlayer) {
	if (event.all_log.key == "money" && state.gameState.phase == "treasure")
		newMoney = <number>event.all_log.value;
	else
		appendLog('update', '', '', '{<strong>' + event.all_log.key + '</strong>=' + event.all_log.value + '}');
    state.updateCurrentPlayer(event.all_log.key, event.all_log.value);
  }

  declare class PhaseChange extends EventBase {
    all_log: {
      new_phase: string;
    }
  }

  function handlePhaseChange(state: ClientState, event: PhaseChange) {
	if (event.all_log.new_phase == "treasure")
		newMoney = null;
	if (state.gameState.phase == "treasure" && newMoney) {
		flushLog(null);
		log(null, 'update', '{<strong>money</strong>=' + newMoney + '}');
	}
    log(null, "phase_change", event.all_log.new_phase);
    state.updatePhase(event.all_log.new_phase);
  }

  declare class MoveCard extends EventBase {
    all_log: {
      from_player: string;
      from_zone: string;
      from_size: number;

      revealed: Card;

      to_player: string;
      to_zone: string;
      to_size: number;
    }
  }

  var currentLogKey: string;
  var currentLogType: string;
  var currentLog: string = "";

  function appendLog(type: string, key: string, initial: string, message: string) {
    if (currentLogType == type && key == currentLogKey) {
      currentLog += " " + message;
    } else {
      if (currentLog.length) {
        log(null, currentLogType, currentLog);
      }
      currentLogType = type;
      currentLogKey = key;
      currentLog = initial + message;
    }
  }

  function handleMoveCard(state: ClientState, event: MoveCard) {
    var removed = event.find("from_card");
    var removed_card_name: string = removed && removed.value.template_name || "a card";

    var pic = null;

    var noLog = false;

    if (event.all_log.from_zone == "hand")
      state.removeFromHand(event.all_log.from_player, removed && removed.value);
    else if (removed && event.all_log.from_zone.lastIndexOf("supply", 0) === 0) {
      pic = 'card_buy';
      state.removeFromSupply(event.all_log.from_zone, event.all_log.revealed, event.all_log.from_size);
    }
    else if (event.all_log.from_zone == "deck")
      state.removeFromDeck(event.all_log.from_player, event.all_log.from_size);
    else if (event.all_log.from_zone == 'play_area')
      state.removeFromPlayArea(removed.value);
    else if (event.all_log.from_zone == 'revealed')
      noLog = true;


    var added = event.find("to_card");
    var added_card_name: string = added && added.value.template_name || "a card";

    if (event.all_log.to_zone == "play_area") {
      state.addToPlayArea(added.value);
      pic = 'card_play';
    }
    else if (event.all_log.to_zone == "hand") {
      state.addToHand(event.all_log.to_player, added && added.value || null, event.all_log.to_size);
      if (added && added.scope == "player")
        pic = 'you_card_draw';
      else
        pic = 'card_draw';
    }
    else if (event.all_log.to_zone == "discard") {
      state.addToDiscard(event.all_log.to_player, added.value, event.all_log.to_size);
      pic = pic || 'card_discard';
    }
    else if (event.all_log.to_zone == "supply")
      state.addToSupply(event.all_log.to_zone, added.value, event.all_log.to_size);
    else if (event.all_log.to_zone == "revealed")
      pic = 'card_reveal';

    var definite = added && added.value.template_name || removed && removed.value.template_name || 'a card';

    if (!noLog) {
      if (pic) {
        appendLog(pic, event.all_log.to_player, "<strong>" + event.all_log.to_player + "</strong>: ", definite);
      } else {
        log(event, null, "Moving (" + definite + ") from: " + event.all_log.from_player + "/" + event.all_log.from_zone + " to: " + event.all_log.to_player + "/" + event.all_log.to_zone);
      }
    }

  }

  export declare class Maybe {
    scope: string;
    value: any;
  }

  export declare class EventBase {
    event_index: number;
    find(key:string) : Maybe;
    get(key:string) : any;
  }
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

class ClientDirtyBits {
  phase: boolean;
  hand: boolean;
  playArea: boolean;
  currentPlayer: boolean;
  myDiscard: boolean;
  supplies: boolean;
  deck: boolean;
  opponents: boolean;

  instructions: boolean;
}

class FilterComplete {
  static exactly(cards: any, num: number) {
    return cards.length == num;
  }
  static at_least(cards: any, num: number) {
    return cards.length >= num;
  }
  static at_most(cards: any, num: number) {
		return cards.length <= num;
  }
}

class FilterSelect {
  static exactly(cards: any, card: Card, num: number) {
    return cards.length < num;
  }
  static at_least(cards: any, card: Card, num: number) {
    return true;
  }
  static at_most(cards: any, card: Card, num: number) {
    return cards.length < num;
  }
}

class SupplyPiles {
  kingdom: Array<FaceUpPile>;
  treasure: Array<FaceUpPile>;
  victory: Array<FaceUpPile>;

  constructor() {
    this.kingdom = [];
    this.treasure = [];
    this.victory = [];
  }
}

class ClientState {
  gameState: GameState;
  dirty: ClientDirtyBits;
  instructions: string;

  clickCard: Function;
  advance: Function;

  supplies: SupplyPiles;

  constructor() {
    this.dirty = new ClientDirtyBits();
    this.instructions = "";
  }

  addOpponent(opp: Opponent) {
    this.gameState.opponents.push(opp);
    this.dirty.opponents = true;
  }

  setInstructions(n: string) {
    this.instructions = n;
    this.dirty.instructions = true;
  }

  fullUpdate(newState) {
    this.gameState = newState;
    this.supplies = new SupplyPiles();
    this.gameState.supplies.forEach((x) => {
      this.supplies[x.supply_type].push(x);
    });
  }

  findPlayer(name: string) {
    for (var i = 0; i < this.gameState.opponents.length; i++) {
      if (this.gameState.opponents[i].name == name) {
        return this.gameState.opponents[i];
      }
    }
    return null;
  }

  removeFromDeck(player: string, newSize: number) {
    if (player == this.gameState.player.name) {
      this.gameState.player.deck_size = newSize;
      this.dirty.deck = true;
    } else {
      this.findPlayer(player).deck_size--;
      this.dirty.opponents = true;
    }
  }

  addToHand(player: string, card: Card, newSize: number) {
    if (player == this.gameState.player.name) {
      this.gameState.player.hand.push(card);
      this.dirty.hand = true;
    } else {
      this.findPlayer(player).hand_size++;
      this.dirty.opponents = true;
    }
  }

  removeFromHand(player: string, card: Card) {
    if (player == this.gameState.player.name) {
      for (var i = 0; i < this.gameState.player.hand.length; i++) {
        if (this.gameState.player.hand[i].id == card.id) {
          this.gameState.player.hand.splice(i, 1);
          break;
        }
      }
      this.dirty.hand = true;
    } else {
      this.findPlayer(player).hand_size--;
      this.dirty.opponents = true;
    }
  }

  /*
  wtf add and remove are the same???
  */
  addToSupply(supply: string, newTop: Card, newSize: number) {
    this.gameState.supplies.forEach((pile) => {
      if (pile.id == parseInt(supply.substring(7))) {
        pile.top = newTop;
        pile.size = newSize;
      }
    });

    this.dirty.supplies = true;
  }
  removeFromSupply(supply: string, newTop: Card, newSize: number) {
    this.gameState.supplies.forEach((pile) => {
      if (pile.id == parseInt(supply.substring(7))) {
        pile.top = newTop;
        pile.size = newSize;
      }
    });

    this.dirty.supplies = true;
  }

  addToDiscard(player: string, card: Card, newSize: number) {
    if (player == this.gameState.player.name) {
      this.gameState.player.discard.size = newSize;
      this.gameState.player.discard.top = card;

      this.dirty.myDiscard = true;
    } else {
      var opp = this.findPlayer(player);
      opp.discard.size = newSize;
      opp.discard.top = card;

      this.dirty.opponents = true;
    }
  }

  removeFromPlayArea(card: Card) {
    for(var i = 0; i < this.gameState.play_area.length; i++) {
      if (this.gameState.play_area[i].id == card.id) {
        this.gameState.play_area.splice(i, 1);
        break;
      }
    }
    this.dirty.playArea = true;
  }

  addToPlayArea(card: Card) {
    this.gameState.play_area.push(card);
    this.dirty.playArea = true;
  }

  setFunctions(clickCardFunc: Function, advanceFunc: Function) {
    this.clickCard = clickCardFunc;
    this.advance = advanceFunc;
  }

  createSupply = (supply) => {
    this.gameState.supplies.push(supply);
    this.supplies[supply.supply_type].push(supply);
    this.dirty.supplies = true;
  }

  recycleDeck = (player: string, newDeckSize: number) => {
    if (player == this.gameState.player.name) {
      this.gameState.player.discard.top = null;
      this.gameState.player.discard.size = 0;
      this.gameState.player.deck_size = newDeckSize;
      this.dirty.myDiscard = true;
      this.dirty.deck = true;
    } else {
      var opp = this.findPlayer(player);
      opp.discard.top = null;
      opp.discard.size = 0;
      opp.deck_size = newDeckSize;
      this.dirty.opponents = true;
    }
  }

	playerConnected = (player: string, connected: boolean) => {
		var opponent = this.findPlayer(player);
		opponent.connected = connected;
		this.dirty.opponents = true;
	}

  updateCurrentPlayer = (key, value) => {
    this.gameState.current_player[key] = value;
    this.dirty.currentPlayer = true;
  }

  updatePhase = (newPhase) => {
    this.gameState.phase = newPhase;
	if (this.gameState.current_player.name == this.gameState.player.name) {
		this.dirty.hand = true; //Note: Dirty the hand so we force a re-sort since the hand sorting is per-phase, this should really only happen if it's your turn but yolo
	}
    this.dirty.phase = true;
  }
  
  handleDialog(raw: any) {
    switch (raw.get('dialog_type')) {
      case 'choose_cards':
        this.setInstructions(raw.get('prompt'));
        this.handleChooseCards(<Events.ChooseCards>raw);
        break;
      default:
        console.log("Unknown dialog: " + JSON.stringify(raw));
        break;
    }
  }

  handleChooseCards(event: Events.ChooseCards) {
    if (event.get('source') == "hand") {
      var selected = {};
      selected['length'] = 0;
      this.setFunctions(
        function(game, source, card) {
          if (source == "hand") {
            if (selected.hasOwnProperty('' + card.id)) {
              delete selected['' + card.id]
              selected['length']--;
              card.marked = false;
            } else {
              if (FilterSelect[event.get('count_type')](selected, card, event.get('count_value'))) {
                selected['' + card.id] = true;
                card.marked = true;
                selected['length']++;
              }
            }

            game.drawHand();
          }
        },
        function(game) {
          if (FilterComplete[event.get('count_type')](selected, event.get('count_value'))) {
            var cards = [];
            delete selected['length']
            for (var key in selected) {
              cards.push(key);
            }
            game.trigger('dialog_respond_event', {dialog_id: event.get('id'), cards: cards});
            this.setInstructions('Waiting for players...');

            this.setFunctions(doNothing, doNothing);
          }
        }
      );
    }
  }
}

declare var game_id: number;
declare var player_id: number;

class Util {
  public static CardWidth: number = 128;
  public static CardPadded: number = 130;
  public static CardHeight: number = 196;
  public static CardHeightPadded: number = 200;
  public static Padding: number = 10;
}

class Asset {
  static image(name) {
    return "/assets/" + name;
  }
}

class CursorSet {
  discard: Phaser.Sprite;
  normal: Phaser.Sprite;
  play: Phaser.Sprite;

  current: Phaser.Sprite;

  setCursor = (newCursor) => {
    if (newCursor != this.current) {
      if (this.current)
        this.current.visible = false;

      this.current = newCursor;
      this.current.visible = true;
      this.current.bringToTop();
    }
  }

  setNormal = () => {
    this.setCursor(this.normal);
  }
  setDiscard = () => {
    this.setCursor(this.discard);
  }
  setPlay = () => {
    this.setCursor(this.play);
  }

  update = (game: Phaser.Game) => {
    this.current.bringToTop();
    this.current.position = game.input.mousePointer.position;
  }
}

function doNothing() { }

var oppTitleStyle: any = { font: "14px Arial" };
var oppTextStyle: any = { font: "10px Arial" };

function textLine(group: Phaser.Group, game: Phaser.Game, xpos: number, ypos: number, keyText: string, valueText: string, style: any) {
  var text = game.add.text(0, 0, keyText, style);
  text.x = xpos;
  text.y = ypos;
  group.add(text);

  if (valueText) {
    text = game.add.text(0, 0, valueText, style);
    text.x = xpos + 50;
    text.y = ypos;
    group.add(text);
  }
}

class CardGame {

  game: Phaser.Game;
  dispatcher: WebSocketRails;
  channel: Channel;
  state: ClientState;
	debugMode: Boolean;

  handWidgets: Phaser.Group;
  playAreaWidgets: Phaser.Group;
  supplyWidgets: Phaser.Group;
  discardWidgets: Phaser.Group;
  deckWidgets: Phaser.Group;
  devWidgets: Phaser.Group;

  turnIndicator: Phaser.Text;
  currentPlayerStatus: Phaser.Text;

  cursors: CursorSet;

  instructions: Phaser.Text;

  opponentsWidgets: Phaser.Group;


  constructor() {
    this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'play-area', { preload: this.preload, create: this.create, update: this.update });
    this.state = new ClientState();
    this.cursors = new CursorSet();
		this.debugMode = false;
  }

  update = () => {
    this.cursors.update(this.game);
  }

  preload = () => {
    this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
    this.game.load.image('card_face_selected', Asset.image('card_face_selected.png'));
    this.game.load.image('small_card_face_empty', Asset.image('small_card_face_empty.png'));
    this.game.load.image('button', Asset.image('button.png'));
    this.game.load.image('cursor_discard', Asset.image('cursor_discard.png'));
    this.game.load.image('cursor_normal', Asset.image('cursor_normal.png'));
    this.game.load.image('cursor_play', Asset.image('cursor_play.png'));
  }

  drawPlayArea = (cards: Array<Card>, group: Phaser.Group) => {
    group.removeAll(true, true);
    var xpos: number = 10;
    cards.forEach((x) => {
      var text = this.game.add.text(0, 0, x.template_name, {font: "10px Arial"});
      text.x = xpos + 20;
      text.y = 64;
      text.angle = -90;

      var sprite = group.create(xpos, 0, 'card_face_empty');
      sprite.inputEnabled = true;
      sprite.events.onInputDown.add(() => {
        this.trigger('card_play_event', {card_id: x.id});
      }, this);
      group.add(text);

      xpos = xpos + 40;
    });

  }

	drawDevOptions = () => {
		this.devWidgets.removeAll(true, true);
		var text;
		if (this.debugMode) {
			text = this.game.add.text(20, 10, "Debug Enabled", {font: "bold 12px Arial", fill: "#FFFF00"});
		} else {
			text = this.game.add.text(20, 10, "Enable Debug", {font: "12px Arial", fill: "#FFFF00"});
		}
    var debugButton = this.game.add.button(0, 0, 'button', () => { this.toggleDebug(); });
		debugButton.addChild(text);
		this.devWidgets.add(debugButton);
	}

	toggleDebug = () => {
		this.debugMode = !this.debugMode;
		this.drawDevOptions();
	}

  drawDeck = () => { 
    this.deckWidgets.removeAll();
    var deckGraphic = this.deckWidgets.create(0, 0, 'card_face_empty');
    deckGraphic.tint = 0x666666;

    var text = this.game.add.text(0, 0, "" + this.state.gameState.player.deck_size, {font: "10px Arial"});
    text.x = 30;
    text.y = 20;

    this.deckWidgets.add(text);
  }

  drawDiscard = () => {
    this.discardWidgets.removeAll();

    if (this.state.gameState.player.discard.top != null) {
      this.discardWidgets.create(0, 0, 'card_face_empty');

      var text = this.game.add.text(0, 0, 
        "DISCARD (" + this.state.gameState.player.discard.size + ")", {font: "10px Arial"});
      text.x = 30;
      text.y = 20;

      this.discardWidgets.add(text);

      var text = this.game.add.text(0, 0, 
        "" + this.state.gameState.player.discard.top.template_name, {font: "10px Arial"});
      text.x = 30;
      text.y = 40;

      this.discardWidgets.add(text);
    }
  }



  drawOpponents = () => {
    var xpos = 0;
    this.opponentsWidgets.removeAll(true, true);

    this.state.gameState.opponents.forEach((opp) => {
      textLine(this.opponentsWidgets, this.game, xpos, 20, opp.name + (opp.connected ? "" : "(disconnected)"), null, oppTitleStyle);
      textLine(this.opponentsWidgets, this.game, xpos, 40, 'Hand#', '' + opp.hand_size, oppTextStyle);
      textLine(this.opponentsWidgets, this.game, xpos, 60, 'Deck#', '' + opp.deck_size, oppTextStyle);
      textLine(this.opponentsWidgets, this.game, xpos, 80, 'Discard#', '' + opp.discard.size, oppTextStyle);
      textLine(this.opponentsWidgets, this.game, xpos, 100, 'Discard', opp.discard.top && opp.discard.top.template_name, oppTextStyle);

      xpos += 150;

    });
  }

  drawHand = () => {
    var cards = this.state.gameState.player.hand;
    var group = this.handWidgets;

    group.removeAll(true, true);
    var sorted = cards.sort((a,b) => {

      if (a.template_name == b.template_name)
        return 0;

      if (a.is_treasure) {
        if (b.is_treasure) {
          if (a.money == b.money) {
            return a.template_name.localeCompare(b.template_name)
          } else {
            return b.money - a.money;
          }
        } else if (b.is_action) {
          //In action phase, actions come before treasure
          return this.state.gameState.phase == "action" ? 1 : -1;
        } else {
          return -1;
        }
      } else if (a.is_action) {
        if (b.is_action) {
          return a.template_name.localeCompare(b.template_name);
        } else if (b.is_treasure) {
          return (this.state.gameState.phase == "treasure" || this.state.gameState.phase == "buy") ? 1 : -1;
        } else {
          return -1;
        }
      } else {
        if (b.is_action || b.is_treasure)
          return 1;
        else
          return a.template_name.localeCompare(b.template_name);
      }
    });

    var xpos: number = 0;
    var last = null;
    sorted.forEach((x) => {

      if (last == null || x.template_name == last.template_name) {
        xpos += 10
      } else {
        xpos += (10 + Util.CardPadded);
      }

      var text = this.game.add.text(0, 0, x.template_name + "\n cost: " + x.cost , {font: "10px Arial"});
      text.x = xpos + 30;
      text.y = 20;


      var bg = 'card_face_empty';
      if (x.marked) {
        bg = 'card_face_selected'
        text.y -= 80;
      }
      var sprite = group.create(xpos, x.marked ? -80 : 0, bg);
      sprite.inputEnabled = true;
      sprite.events.onInputDown.add(() => {
        this.clickCard('hand', x);
      }, this);
      group.add(text);

      last = x;

    });

  }

  clickCard = (source, card) => {
    if (this.state.clickCard) {
      this.state.clickCard(this, source, card);
    } else {
      this.trigger('card_play_event', {card_id: card.id});
    }
  }

  drawSupplyPile = (supply: FaceUpPile, xpos: number, ypos: number) => {
      var sprite = this.supplyWidgets.create(xpos, ypos, 'small_card_face_empty');

      if (supply.top != null) {
        var text = this.game.add.text(0, 0, supply.top.template_name + "(" + supply.size + ")\n cost: " + supply.top.cost , {font: "10px Arial"});
        text.x = xpos + 30;
        text.y = ypos + 20;
        this.supplyWidgets.add(text);

        sprite.inputEnabled = true;
        sprite.events.onInputDown.add(() => {
          this.trigger('card_buy_event', {supply_id: supply.id});
        }, this);
      }
  }

  drawSupplies = () => {
    this.supplyWidgets.removeAll(true, true);

    var ypos = 0;
    this.state.supplies.treasure.forEach((supply) => {
      this.drawSupplyPile(supply, Util.CardPadded, ypos);
      ypos += 68;
    });
    ypos += 68;
    this.state.supplies.victory.forEach((supply) => {
      this.drawSupplyPile(supply, Util.CardPadded, ypos);
      ypos += 68;
    });

    ypos = 0;
    this.state.supplies.kingdom.sort(function(a,b) {
      if (a.top) {
        if (b.top)
          return a.top.cost - b.top.cost;
        else
          return -1;
      } else {
        if (b.top)
          return 1;
        else
          return 0;
      }

    }).forEach((supply) => {
      this.drawSupplyPile(supply, 0, ypos);
      ypos += 68;
    });

  }

  onFullGameState = (data) => {
		if (this.debugMode) {
			console.log("Full game state at: " + new Date());
	    console.log(JSON.stringify(data));
		}
    this.state.fullUpdate(data.game);
    this.drawHand();
    this.drawPlayArea(this.state.gameState.play_area, this.playAreaWidgets);
		this.drawDevOptions();
    this.turnIndicator.setText("Player: " + this.state.gameState.current_player.name + " Phase: " + this.state.gameState.phase);
    this.currentPlayerStatus.setText("Money: " + this.state.gameState.current_player.money + " Buys: " + this.state.gameState.current_player.buys + " Actions: " + this.state.gameState.current_player.actions);

    this.drawDiscard();
    this.drawDeck();
    this.drawSupplies();

    this.drawOpponents();

    if (this.state.gameState.dialogs) {
      this.state.gameState.dialogs.forEach((dialog) => {
        var ev = { player_log: dialog };
        Events.event(ev);
        this.state.handleDialog(ev);
      });
    }
  }

  trigger = (eventName, data) => {
    this.dispatcher.trigger(eventName, JSON.stringify({game_id: game_id, data: data }));
  }

  getTexture = (key: string) : Phaser.RenderTexture => {
    return null;
  }

  doChat = (message) => {
    if (message.length > 0) {
      this.trigger('chat_event', {message: message});
    }
  }

  doAdvance = () => {
    if (this.state.advance)
      this.state.advance(this);
    else
      this.trigger('phase_advance_event', null);
  }

  onChat = (data) => {
    $("#chat-tab-all-chat").prepend('<div><span class="chat-sender">' + data.from + '</span><span> ' + data.message + '</span></div>');
  }

  onGameUpdate = (data) => {

		if (this.debugMode) {
			console.log("Game update at: " + new Date());
			console.log(JSON.stringify(data));
		}

    data.forEach((logEvent) => {

			if (this.debugMode) {
				console.log("Processing event at " + new Date());
	    	console.log(JSON.stringify(logEvent));
			}

      Events.handle(this.state, logEvent);
    });

    Events.flushLog(this.state);

		this.drawDevOptions();

    if (this.state.dirty.opponents) {
      this.drawOpponents();
      this.state.dirty.opponents = false;
    }

    if (this.state.dirty.deck) {
      this.drawDeck();
      this.state.dirty.deck = false;
    }

    if (this.state.dirty.supplies) {
      this.drawSupplies();
      this.state.dirty.supplies = false;
    }

    if (this.state.dirty.myDiscard) {
      this.drawDiscard();
      this.state.dirty.myDiscard = false;
    }

    if (this.state.dirty.playArea) {
      this.drawPlayArea(this.state.gameState.play_area, this.playAreaWidgets);
      this.state.dirty.playArea = false;
    }

    if (this.state.dirty.hand) {
      this.drawHand();
      this.state.dirty.hand = false;
    }

    if (this.state.dirty.phase) {
      this.turnIndicator.setText("Player: " + this.state.gameState.current_player.name + " Phase: " + this.state.gameState.phase);
      this.state.dirty.phase = false;
    }

    if (this.state.dirty.currentPlayer) {
      this.currentPlayerStatus.setText("Money: " + this.state.gameState.current_player.money + " Buys: " + this.state.gameState.current_player.buys + " Actions: " + this.state.gameState.current_player.actions);
      this.state.dirty.phase = false;
    }

    if (this.state.dirty.instructions) {
      this.instructions.setText(this.state.instructions);
      this.state.dirty.instructions = false;
    }
  }

  create = () => {
    this.game.stage.backgroundColor = 0xefefef;
    this.turnIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});
    this.currentPlayerStatus = this.game.add.text(0, 40, "Status: ???", {font: "14px Arial"});

    this.instructions = new Phaser.Text(this.game, 0, 0, "", {font: "32px Arial", fill: "#0000aa"});
    this.instructions.position.set(100, 200);
    this.game.stage.addChild(this.instructions);

    this.cursors.discard = this.game.add.sprite(0, 0, 'cursor_discard');
    this.cursors.normal = this.game.add.sprite(0, 0, 'cursor_normal');
    this.cursors.play = this.game.add.sprite(0, 0, 'cursor_play');
    this.cursors.discard.visible = false;
    this.cursors.play.visible = false;
    this.cursors.setCursor(this.cursors.normal);

    var label = new Phaser.Text(this.game, 20, 10, "Advance", {font: "12px Arial", fill: "#ffff00"});
    var advanceButton = this.game.add.button(400, 0, 'button', () => { this.doAdvance(); });
    advanceButton.addChild(label);

    this.opponentsWidgets = this.game.add.group();
    this.opponentsWidgets.x = 10;
    this.opponentsWidgets.y = 100;

    this.handWidgets = this.game.add.group();
    this.handWidgets.x = 10;
    this.handWidgets.y = this.game.height - 200;

    this.playAreaWidgets = this.game.add.group();
    this.playAreaWidgets.x = 10;
    this.playAreaWidgets.y = this.game.height - 500;

    this.discardWidgets = this.game.add.group();
    this.discardWidgets.x = this.game.width - (Util.CardPadded * 3);
    this.discardWidgets.y = this.game.height - (Util.CardHeightPadded * 3);

    this.deckWidgets = this.game.add.group();
    this.deckWidgets.x = this.game.width - (Util.CardPadded * 3);
    this.deckWidgets.y = this.game.height - (Util.CardHeightPadded * 2);

    this.supplyWidgets = this.game.add.group();
    this.supplyWidgets.x = this.game.width - (Util.CardPadded * 2);
    this.supplyWidgets.y = 10;

		this.devWidgets = this.game.add.group();
		this.devWidgets.x = advanceButton.x + 180;
		this.devWidgets. y = 0

    this.dispatcher = new WebSocketRails(location.host + "/websocket", true);

    this.channel = this.dispatcher.subscribe('game_updates_' + game_id);
    this.channel.bind('full_game_state_' + player_id, (data) => {this.onFullGameState(data);});
    this.channel.bind('update_game_state_' + player_id, (data) => {this.onGameUpdate(data);});
    this.channel.bind('game_chat_event', (data) => {this.onChat(data);});
    this.channel.bind('player_joined_event', (data) => {
      this.state.addOpponent(data);
      this.drawOpponents();
    });


    this.trigger('game_fetch_event', null);
  }

}

var game;

window.onload = () => {
  game = new CardGame();
  $("#chat-text-input").bind('keypress', function(ev) {
    if (ev.which == 13) {
      ev.preventDefault();
      game.doChat($(this).val().trim());
      $(this).val("");
    }
  });
}

