
/// <reference path="phaser.d.ts" />

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

    template_name: string;

    is_action: boolean;
    is_treasure: boolean;
    is_victory: boolean;
}

declare class FaceUpPile {
  size: number;
  top: Card;
}

declare class You {
  deck_size: number;
  hand: Array<Card>;
}

declare class Player {
  name: string;
}

declare class GameState {
  phase: string;
  current_player: Player;
  player: You;
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

    turnIndicator: Phaser.Text;

    constructor() {
        this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'content', { preload: this.preload, create: this.create });
    }

    preload = () => {
        this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
        this.game.load.image('button', Asset.image('button.png'));
    }

    onFullGameState = (data) => {
      this.state = data.game;
      this.handWidgets.removeAll(true, true);
      var xpos: number = 10;
      this.state.player.hand.forEach((x) => {
        var text = this.game.add.text(0, 0, x.template_name, {font: "10px Arial"});
        text.x = xpos + 30;
        text.y = 20;
        this.handWidgets.create(xpos, 0, 'card_face_empty');
        this.handWidgets.add(text);

        xpos = xpos + Util.CardPadded;
      });

      this.turnIndicator.setText("Player: " + this.state.current_player.name + " Phase: " + this.state.phase);
    }

    trigger = (eventName, data) => {
      this.dispatcher.trigger(eventName, JSON.stringify({game_id: game_id, data: data }));
    }

    getTexture = (key: string) : Phaser.RenderTexture => {
      return null;
    }

    doAdvance = () => {
        this.trigger('phase_advance_event', null);
        this.trigger('game_fetch_event', null);
    }

    create = () => {
        this.game.stage.backgroundColor = 0xefefef;
        this.turnIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});

        var label = new Phaser.Text(this.game, 20, 10, "Advance", {font: "12px Arial", fill: "#ffff00"});
        var advanceButton = this.game.add.button(400, 0, 'button', () => { this.doAdvance(); });
				advanceButton.addChild(label);

        this.handWidgets = this.game.add.group();
        this.handWidgets.x = 10;
        this.handWidgets.y = this.game.height - 200;

        this.dispatcher = new WebSocketRails(location.host + "/websocket", true);

        this.channel = this.dispatcher.subscribe('game_updates_' + game_id);
        this.channel.bind('full_game_state_' + player_id, (data) => {this.onFullGameState(data);});

        this.trigger('game_fetch_event', null);
    }

}

window.onload = () => {
    var game = new CardGame();
}

