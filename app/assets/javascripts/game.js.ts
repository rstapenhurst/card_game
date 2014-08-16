
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

  export function handle(state: ClientState, raw) {
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
        if (raw.hasOwnProperty('player_log')) {
          switch (raw.player_log.dialog_type) {
            case 'choose_cards':
              handleChooseCards(state, <ChooseCards>raw);
              break;
            default:
              log(null, JSON.stringify(raw));
              break;
          }
        }
        break;
      case 'update_current_player':
        handleUpdateCurrentPlayer(state, <UpdatePlayer>raw);
        break;
      default:
        log(null, JSON.stringify(raw));
        console.log(raw);
        break;
    }
  }

  function log(event: EventBase, message: string) {
    $("#game-log").prepend("<li>[" + (event != null ? ("" + event.event_index) : "***") + "] " + message + "</li>");
  }

  function maybe(event: any, key: string): any {
    if (event.hasOwnProperty('all_log') && event.all_log.hasOwnProperty(key))
      return {value: event.all_log[key], scope: "all"};
    if (event.hasOwnProperty('opponent_log') && event.opponent_log.hasOwnProperty(key))
      return {value: event.opponent_log[key], scope: "opponent"};
    if (event.hasOwnProperty('player_log') && event.player_log.hasOwnProperty(key))
      return {value: event.player_log[key], scope: "player"};

    return null;
  }

  declare class ChooseCards extends EventBase {
    player_log: {
      id: number;
      dialog_type: string;
      source: string;
      count_type: string;
      count_value: number;
      prompt: string;
    }
  }

  function handleChooseCards(state: ClientState, event: ChooseCards) {
    if (event.player_log.source == "hand") {
      var selected = {};
      state.setFunctions(
        function(game, source, card) {
          if (source == "hand") {
            if (selected.hasOwnProperty('' + card.id)) {
              delete selected['' + card.id]
              card.marked = false;
            } else {
              selected['' + card.id] = true;
              card.marked = true;
            }

            game.drawHand();
          }
        },
        function(game) {
          var cards = [];
          for (var key in selected) {
            cards.push(key);
          }
          game.trigger('dialog_respond_event', {dialog_id: event.id, cards: cards});
          console.log("Do a noob");
          console.log(cards);
        }
      );
    }
  }

  declare class CreateSupply extends EventBase {
    all_log: FaceUpPile;
  }

  function handleCreateSupply(state: ClientState, event: CreateSupply) {
    log(event, "Create supply [" + event.all_log.top.template_name + "], size: " + event.all_log.size);
    state.createSupply(event.all_log);
  }

  declare class UpdatePlayer extends EventBase {
    all_log: {
      key: string;
      value: any;
    }
  }


  function handleUpdateCurrentPlayer(state: ClientState, event: UpdatePlayer) {
    log(event, "[" + event.all_log.key + "]  -> " + event.all_log.value);
    state.updateCurrentPlayer(event.all_log.key, event.all_log.value);
  }

  declare class PhaseChange extends EventBase {
    all_log: {
      new_phase: string;
    }
  }

  function handlePhaseChange(state: ClientState, event: PhaseChange) {
    log(event, "Changing phase to: " + event.all_log.new_phase);
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

  function handleMoveCard(state: ClientState, event: MoveCard) {
    var removed = maybe(event, "from_card");
    var removed_card_name: string = removed && removed.value.template_name || "a card";

    if (removed && event.all_log.from_zone == "hand")
      state.removeFromHand(removed.value);
    else if (removed && event.all_log.from_zone.lastIndexOf("supply", 0) === 0)
      state.removeFromSupply(event.all_log.from_zone, event.all_log.revealed, event.all_log.from_size);
    else if (event.all_log.from_zone == "deck")
      state.removeFromDeck(event.all_log.from_player, event.all_log.from_size);
    else if (event.all_log.from_zone == 'play_area')
      state.removeFromPlayArea(removed.value);


    var added = maybe(event, "to_card");
    var added_card_name: string = added && added.value.template_name || "a card";

    if (event.all_log.to_zone == "play_area")
      state.addToPlayArea(added.value);
    else if (event.all_log.to_zone == "hand")
      state.addToHand(event.all_log.to_player, added && added.value || null, event.all_log.to_size);
    else if (event.all_log.to_zone == "discard")
      state.addToDiscard(event.all_log.to_player, added.value, event.all_log.to_size);
    else if (event.all_log.to_zone == "supply")
      state.addToSupply(event.all_log.to_zone, added.value, event.all_log.to_size);

    var definite = added && added.value.name || removed && removed.value.name || 'a card';

    log(event, "Moving (" + definite + ") from: " + event.all_log.from_player + "/" + event.all_log.from_zone + " to: " + event.all_log.to_player + "/" + event.all_log.to_zone);
  }

  declare class EventBase {
    event_index: number;
  }
}

declare class FaceUpPile {
  id: number;
  size: number;
  top: Card;
  name: string;
}

declare class You {
  name: string;
  deck_size: number;
  hand: Array<Card>;
  discard: FaceUpPile;
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
  play_area: Array<Card>;
  supplies: Array<FaceUpPile>;
}

class ClientDirtyBits {
  phase: boolean;
  hand: boolean;
  playArea: boolean;
  currentPlayer: boolean;
  myDiscard: boolean;
  supplies: boolean;
  deck: boolean;

  instructions: boolean;

}

class ClientState {
  gameState: GameState;
  dirty: ClientDirtyBits;
  instructions: string;

  clickCard: Function;
  advance: Function;

  constructor() {
    this.dirty = new ClientDirtyBits();
    this.instructions = "";
  }

  setInstructions(n: string) {
    this.instructions = n;
    this.dirty.instructions = true;
  }

  fullUpdate(newState) {
    this.gameState = newState;
  }

  removeFromDeck(player: string, newSize: number) {
    if (player == this.gameState.player.name) {
      this.gameState.player.deck_size = newSize;
      this.dirty.deck = true;
    }
  }

  addToHand(player: string, card: Card, newSize: number) {
    if (player == this.gameState.player.name) {
      this.gameState.player.hand.push(card);
      this.dirty.hand = true;
    }
  }

  removeFromHand(card: Card) {
    for (var i = 0; i < this.gameState.player.hand.length; i++) {
      if (this.gameState.player.hand[i].id == card.id) {
        this.gameState.player.hand.splice(i, 1);
        break;
      }
    }
    this.dirty.hand = true;
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
    this.dirty.supplies = true;
  }

  updateCurrentPlayer = (key, value) => {

    this.gameState.current_player[key] = value;
    this.dirty.currentPlayer = true;
  }

  updatePhase = (newPhase) => {
    this.gameState.phase = newPhase;
    this.dirty.phase = true;
  }
}

declare var game_id: number;
declare var player_id: number;

class Util {
  public static CardWidth: number = 128;
  public static CardPadded: number = 130;
  public static CardHeight: number = 196;
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

class CardGame {

  game: Phaser.Game;
  dispatcher: WebSocketRails;
  channel: Channel;
  state: ClientState;

  handWidgets: Phaser.Group;
  playAreaWidgets: Phaser.Group;
  supplyWidgets: Phaser.Group;
  discardWidgets: Phaser.Group;
  deckWidgets: Phaser.Group;

  turnIndicator: Phaser.Text;
  currentPlayerStatus: Phaser.Text;

  cursors: CursorSet;

  instructions: Phaser.Text;


  constructor() {
    this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'play-area', { preload: this.preload, create: this.create, update: this.update });
    this.state = new ClientState();
    this.cursors = new CursorSet();
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
      }
      var sprite = group.create(xpos, 0, bg);
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

  drawSupplies = () => {
    this.supplyWidgets.removeAll(true, true);
    var ypos = 0;
    this.state.gameState.supplies.forEach((x) => {
      var sprite = this.supplyWidgets.create(0, ypos, 'small_card_face_empty');

      if (x.top != null) {
        var text = this.game.add.text(0, 0, x.top.template_name + "(" + x.size + ")\n cost: " + x.top.cost , {font: "10px Arial"});
        text.x = 30;
        text.y = ypos + 20;
        this.supplyWidgets.add(text);

        sprite.inputEnabled = true;
        sprite.events.onInputDown.add(() => {
          this.trigger('card_buy_event', {supply_id: x.id});
        }, this);
      }

      ypos = ypos + 68;
    });
  }

  onFullGameState = (data) => {
    this.state.fullUpdate(data.game);
    this.drawHand();
    this.drawPlayArea(this.state.gameState.play_area, this.playAreaWidgets);
    this.turnIndicator.setText("Player: " + this.state.gameState.current_player.name + " Phase: " + this.state.gameState.phase);
    this.currentPlayerStatus.setText("Money: " + this.state.gameState.current_player.money + " Buys: " + this.state.gameState.current_player.buys + " Actions: " + this.state.gameState.current_player.actions);

    this.drawDiscard();
    this.drawDeck();
    this.drawSupplies();


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
    data.forEach((logEvent) => {
      Events.handle(this.state, logEvent);
    });

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
      this.state.dirty.instructions = false;
    }
  }

  create = () => {
    this.game.stage.backgroundColor = 0xefefef;
    this.turnIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});
    this.currentPlayerStatus = this.game.add.text(0, 40, "Status: ???", {font: "14px Arial"});

    this.instructions = new Phaser.Text(this.game, 0, 0, "", {font: "24px Arial"});

    this.cursors.discard = this.game.add.sprite(0, 0, 'cursor_discard');
    this.cursors.normal = this.game.add.sprite(0, 0, 'cursor_normal');
    this.cursors.play = this.game.add.sprite(0, 0, 'cursor_play');
    this.cursors.discard.visible = false;
    this.cursors.play.visible = false;
    this.cursors.setCursor(this.cursors.normal);

    var label = new Phaser.Text(this.game, 20, 10, "Advance", {font: "12px Arial", fill: "#ffff00"});
    var advanceButton = this.game.add.button(400, 0, 'button', () => { this.doAdvance(); });
    advanceButton.addChild(label);

    this.handWidgets = this.game.add.group();
    this.handWidgets.x = 10;
    this.handWidgets.y = this.game.height - 200;

    this.playAreaWidgets = this.game.add.group();
    this.playAreaWidgets.x = 10;
    this.playAreaWidgets.y = this.game.height - 400;

    this.discardWidgets = this.game.add.group();
    this.discardWidgets.x = this.game.width - (Util.CardPadded * 2);
    this.discardWidgets.y = this.game.height - (Util.CardHeight * 2);

    this.deckWidgets = this.game.add.group();
    this.deckWidgets.x = this.game.width - (Util.CardPadded * 3);
    this.deckWidgets.y = this.game.height - (Util.CardHeight * 2);

    this.supplyWidgets = this.game.add.group();
    this.supplyWidgets.x = this.game.width - Util.CardPadded;
    this.supplyWidgets.y = 10;

    this.dispatcher = new WebSocketRails(location.host + "/websocket", true);

    this.channel = this.dispatcher.subscribe('game_updates_' + game_id);
    this.channel.bind('full_game_state_' + player_id, (data) => {this.onFullGameState(data);});
    this.channel.bind('update_game_state_' + player_id, (data) => {this.onGameUpdate(data);});
    this.channel.bind('game_chat_event', (data) => {this.onChat(data);});

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

