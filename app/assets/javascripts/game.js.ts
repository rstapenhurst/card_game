﻿
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
}

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

    turnIndicator: Phaser.Text;


    constructor() {
      console.log(x);
        this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'content', { preload: this.preload, create: this.create });
    }

    preload = () => {
        this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
        this.game.load.image('button', Asset.image('button.png'));
    }

    onFullGameState = (data) => {
      console.log(data);
      this.state = data.game;
      this.turnIndicator.setText("Player: " + this.state.current_player.name + " Phase: " + this.state.phase);
    }

    trigger = (eventName, data) => {
      this.dispatcher.trigger(eventName, JSON.stringify({game_id: 1, data: data }));
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

        this.dispatcher = new WebSocketRails(location.host + "/websocket", true);

        this.channel = this.dispatcher.subscribe('game_updates');
        this.channel.bind('full_game_state', (data) => {this.onFullGameState(data);});

        this.trigger('game_fetch_event', null);
    }

}

window.onload = () => {
    var game = new CardGame();
}

