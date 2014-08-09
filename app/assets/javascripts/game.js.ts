
/// <reference path="phaser.d.ts" />

class Util {
    public static CardWidth: number = 128;
    public static CardPadded: number = 130;
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

    contents: Array<Card>;asdas

    sprites: Map<number, Phaser.Sprite>;

    constructor(game: CardGame, type: string) {
        this.type = type;
        this.game = game;
        this.contents = new Array<Card>();
        this.sprites = new Map<number, Phaser.Sprite>();
    }

    addCard(card: Card) {
        this.contents.push(card);
        this.sprites.set(card.id, this.game.game.add.sprite(0, 0, 'card_face_empty'));
    }

}

class CardGame {

    game: Phaser.Game;
    myHand: CardPile;

    constructor() {
        this.game = new Phaser.Game(1200, 900, Phaser.AUTO, 'content', { preload: this.preload, create: this.create });

    }

    preload() {
        this.game.load.image('card_face_empty', 'assets/card_face_empty.png');
    }

    create() {
        this.game.stage.backgroundColor = 0xefefef;
        this.myHand = new CardPile(this, "hand");
        this.myHand.addCard(new Card(0, true));
    }

}

window.onload = () => {
    var game = new CardGame();
}