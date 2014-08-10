
/// <reference path="phaser.d.ts" />

declare class Channel {
  bind(eventName: string, callback: Function);
}

declare class WebSocketRails {
  constructor(url: string, useWebSockets: boolean);
  subscribe(channel: string) : Channel;
  trigger(eventName: string, eventData: string);
}

declare class GameState {
  phase: string;

}

class Util {
    public static CardWidth: number = 128;
    public static CardPadded: number = 130;
    public static CardHeight: number = 196;
    public static Padding: number = 10;
}

class Card {
    faceUp: boolean;

    id: number;

    constructor(id: number, faceUp: boolean) {
        this.id = id;
        this.faceUp = faceUp;
    }

    render = () => {
    }
}

class CardPile {
    type: string;
    game: CardGame;
    group: Phaser.Group;

    contents: Array<Card>;

    sprites: Map<number, Phaser.Sprite>;

    constructor(game: CardGame, type: string, position: Phaser.Point) {
        this.type = type;
        this.game = game;
        this.group = this.game.game.add.group();
        this.group.position = position;
        this.contents = new Array<Card>();
        this.sprites = new Map<number, Phaser.Sprite>();
    }

    addCard(card: Card) {
        this.contents.push(card);
        this.group.create(0, 0, 'card_face_empty');
    }

}

class Asset {
    static image(name) {
			return "/assets/" + name;
    }
}

class CardGame {

    game: Phaser.Game;
    myHand: CardPile;
    playArea: CardPile;
    dispatcher: WebSocketRails;
    channel: Channel;
    state: GameState;

    phaseIndicator: Phaser.Text;

    textures: Map<string, Phaser.RenderTexture>

    constructor() {
        this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'content', { preload: this.preload, create: this.create });
        this.textures = new Map<string, Phaser.RenderTexture>();
    }

    preload = () => {
        this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
    }

    onFullGameState = (data) => {
      console.log(data);
      this.state = data.game;
      this.phaseIndicator.setText("Phase: " + this.state.phase);
    }

    trigger = (eventName, data) => {
      this.dispatcher.trigger(eventName, JSON.stringify({game_id: 1, data: data }));
    }

    getTexture = (key: string) : Phaser.RenderTexture => {
      var tex = textures.get(string);
      if (tex != null)
        return tex;
    }

    create = () => {
        this.game.stage.backgroundColor = 0xefefef;
        this.myHand = new CardPile(this, "hand", new Phaser.Point(Util.Padding + Util.CardWidth + Util.Padding, this.game.height - Util.CardHeight - Util.Padding));
        this.playArea = new CardPile(this, "play-area", new Phaser.Point(Util.Padding + Util.CardWidth + Util.Padding, this.game.height - Util.Padding - Util.CardHeight - Util.Padding));
        this.myHand.addCard(new Card(0, true));
        this.phaseIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});

        this.dispatcher = new WebSocketRails(location.host + "/websocket", true);

        this.channel = this.dispatcher.subscribe('game_updates');
        this.channel.bind('full_game_state', (data) => {this.onFullGameState(data);});

        this.trigger('game_fetch_event', null);
        this.trigger('phase_advance_event', null);
        this.trigger('game_fetch_event', null);

    }

}

window.onload = () => {
    var game = new CardGame();
}

