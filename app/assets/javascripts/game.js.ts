
/// <reference path="phaser.d.ts" />

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
}

class CardPile {
    type: string;
    game: CardGame;
    group: Phaser.Group;

    contents: Array<Card>;asdas

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

    constructor() {
        this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'content', { preload: this.preload, create: this.create });

    }

    preload() {
        this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
    }

    create() {
        this.game.stage.backgroundColor = 0xefefef;
        this.myHand = new CardPile(this, "hand", new Phaser.Point(Util.Padding + Util.CardWidth + Util.Padding, this.game.height - Util.CardHeight - Util.Padding));
        this.playArea = new CardPile(this, "play-area", new Phaser.Point(Util.Padding + Util.CardWidth + Util.Padding, this.game.height - Util.Padding - Util.CardHeight - Util.Padding));
        this.myHand.addCard(new Card(0, true));
    }

}

window.onload = () => {
    var game = new CardGame();
}
