
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
}

declare class FaceUpPile {
  id: number;
  size: number;
  top: Card;
  name: string;
}

declare class You {
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

class CardGame {

  game: Phaser.Game;
  dispatcher: WebSocketRails;
  channel: Channel;
  state: GameState;

  handWidgets: Phaser.Group;
  playAreaWidgets: Phaser.Group;
  supplyWidgets: Phaser.Group;
  discardWidgets: Phaser.Group;
  deckWidgets: Phaser.Group;

  turnIndicator: Phaser.Text;
  currentPlayerStatus: Phaser.Text;

  constructor() {
    this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'play-area', { preload: this.preload, create: this.create });
  }

  preload = () => {
    this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
    this.game.load.image('small_card_face_empty', Asset.image('small_card_face_empty.png'));
    this.game.load.image('button', Asset.image('button.png'));
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

    var text = this.game.add.text(0, 0, "" + this.state.player.deck_size, {font: "10px Arial"});
    text.x = 30;
    text.y = 20;

    this.deckWidgets.add(text);
  }

  drawDiscard = () => {
    this.discardWidgets.removeAll();

    if (this.state.player.discard.top != null) {
      this.discardWidgets.create(0, 0, 'card_face_empty');

      var text = this.game.add.text(0, 0, 
        "DISCARD (" + this.state.player.discard.size + ")", {font: "10px Arial"});
      text.x = 30;
      text.y = 20;

      this.discardWidgets.add(text);

      var text = this.game.add.text(0, 0, 
        "" + this.state.player.discard.top.template_name, {font: "10px Arial"});
      text.x = 30;
      text.y = 40;

      this.discardWidgets.add(text);
    }
  }

  drawHand = (cards: Array<Card>, group: Phaser.Group) => {
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
          return this.state.phase == "action" ? 1 : -1;
        } else {
          return -1;
        }
      } else if (a.is_action) {
        if (b.is_action) {
          return a.template_name.localeCompare(b.template_name);
        } else if (b.is_treasure) {
          return (this.state.phase == "treasure" || this.state.phase == "buy") ? 1 : -1;
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

      var sprite = group.create(xpos, 0, 'card_face_empty');
      sprite.inputEnabled = true;
      sprite.events.onInputDown.add(() => {
        this.trigger('card_play_event', {card_id: x.id});
      }, this);
      group.add(text);

      last = x;

    });

  }

  onFullGameState = (data) => {
    this.state = data.game;
    this.drawHand(this.state.player.hand, this.handWidgets);
    this.drawPlayArea(this.state.play_area, this.playAreaWidgets);
    this.turnIndicator.setText("Player: " + this.state.current_player.name + " Phase: " + this.state.phase);
    this.currentPlayerStatus.setText("Money: " + this.state.current_player.money + " Buys: " + this.state.current_player.buys + " Actions: " + this.state.current_player.actions);

    this.drawDiscard();
    this.drawDeck();

    this.supplyWidgets.removeAll(true, true);
    var ypos = 0;
    this.state.supplies.forEach((x) => {
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
    this.trigger('phase_advance_event', null);
    this.trigger('game_fetch_event', null);
  }

  onChat = (data) => {
  $("#chat-tab-all-chat").prepend('<div><span class="chat-sender">' + data.from + '</span><span> ' + data.message + '</span></div>');
  }
  onGameUpdate = (data) => {
    this.trigger('game_fetch_event', null);
		data.forEach((logEvent) => {
			if (logEvent.player_log != null) {
				$("#game-log").prepend("<li>[" + logEvent.event_index + "] " + logEvent.player_log + "</li>");
			} else {
				$("#game-log").prepend("<li>[" + logEvent.event_index + "] " + logEvent.all_log + "</li>");
			}
    });
  }

  create = () => {
    this.game.stage.backgroundColor = 0xefefef;
    this.turnIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});
    this.currentPlayerStatus = this.game.add.text(0, 40, "Status: ???", {font: "14px Arial"});

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

