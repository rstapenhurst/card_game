/// <reference path="phaser.d.ts" />
/// <reference path="jquery.d.ts" />
/// <reference path="card_game_interfaces.d.ts" />
/// <reference path="game_state.js.ts" />
/// <reference path="game_events.js.ts" />


declare var game_id: number;
declare var player_id: number;

interface SpriteView {
  sprite: Phaser.Sprite;
  group: Phaser.Group;
}

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


var oppTitleStyle: any = { font: "14px Arial" };
var oppTextStyle: any = { font: "10px Arial" };

function optionsStyle() {
  return { 
    font: "18px Arial",
    fill: '#cccccc'
  };
}

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

  modalDialog: Phaser.Group;
  modalContents: Phaser.Group;

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
    this.game.load.spritesheet('checkbox', Asset.image('checkbox.png'), 32, 32);

    this.game.load.image('dialog_bg', Asset.image('dialog_bg.png'));
    this.game.load.image('card_face_empty', Asset.image('card_face_empty.png'));
    this.game.load.image('card_face_selected', Asset.image('card_face_selected.png'));
    this.game.load.image('small_card_face_empty', Asset.image('small_card_face_empty.png'));
    this.game.load.image('button', Asset.image('button.png'));
    this.game.load.image('cursor_discard', Asset.image('cursor_discard.png'));
    this.game.load.image('cursor_normal', Asset.image('cursor_normal.png'));
    this.game.load.image('cursor_play', Asset.image('cursor_play.png'));
  }

  createView = (key: string, textVal: string, parentGroup: Phaser.Group, x: number, y: number, textStyle: any): SpriteView => {
    var cardGroup = this.game.add.group();
    cardGroup.x = x;
    cardGroup.y = y;

    parentGroup.addChild(cardGroup);

    var text = this.game.add.text(0, 0, textVal, textStyle);
    text.x = 40;
    text.y = 10;

    var sprite = cardGroup.create(0, 0, key);
    sprite.inputEnabled = true;

    cardGroup.add(text);

    return { group: cardGroup, sprite: sprite };
  }

  createCardView = (card: Card, parentGroup: Phaser.Group, textRotated: boolean, x: number, y: number): SpriteView => {
    var cardGroup = this.game.add.group();
    cardGroup.x = x;
    cardGroup.y = y;

    parentGroup.addChild(cardGroup);

    var text = this.game.add.text(0, 0, card.template_name + '\n cost:' + card.cost, {font: "10px Arial"});
    text.x = 20;
    text.y = 20;

    if (textRotated) {
      text.y = 64;
      text.angle = -90;
    }

    var sprite;

    if (card.marked)
      sprite = cardGroup.create(0, 0, 'card_face_selected');
    else
      sprite = cardGroup.create(0, 0, 'card_face_empty');

    sprite.inputEnabled = true;

    cardGroup.add(text);

    return { group: cardGroup, sprite: sprite };
  }

  drawCard = (card: Card, parentGroup: Phaser.Group, textRotated: boolean, x: number, y: number, clickFunc: Function) => {
    var view = this.createCardView(card, parentGroup, textRotated, x, y);

    if (clickFunc)
      view.sprite.events.onInputDown.add(() => {clickFunc();}, this);

    return view.group;
  }

  drawPlayArea = (cards: Array<Card>, group: Phaser.Group) => {
    group.removeAll(true, true);
    var xpos: number = 10;
    cards.forEach((x) => {
      this.drawCard(x, group, true, xpos, 0, () => { this.trigger('card_play_event', {card_id: x.id}); });
      //var text = this.game.add.text(0, 0, x.template_name, {font: "10px Arial"});
      //text.x = xpos + 20;
      //text.y = 64;
      //text.angle = -90;

      //var sprite = group.create(xpos, 0, 'card_face_empty');
      //sprite.inputEnabled = true;
      //sprite.events.onInputDown.add(() => {
      //  this.trigger('card_play_event', {card_id: x.id});
      //}, this);
      //group.add(text);

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
        console.log('parsing dialogs');
				console.log(ev);
        this.state.handleDialog(ev);
      });
    }

    this.drawModal();
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


  drawCardset = (g: Phaser.Graphics, cardset: CardsetOption, cx: number, cy: number) => {
    var widthOfCards = cardset.cards.length * Util.CardPadded;

    var x = cx;
    var y = cy;

    var instructionText = this.game.add.text(x, y + 16, 'Choose\n\n', optionsStyle());
    var cardInstructions = this.game.add.text(x, y + 64, cardset.card_count_type + ' ' + cardset.card_count_value + '\ncard(s)', optionsStyle());
    var optInstructions = this.game.add.text(x, y + 128, cardset.option_count_type + ' ' + cardset.option_count_value + '\noption(s)', optionsStyle());

    this.modalContents.addChild(instructionText);
    this.modalContents.addChild(cardInstructions);
    this.modalContents.addChild(optInstructions);

    optInstructions.fill = '#ff0000';

    x += 130;

    var nameText = this.game.add.text(x, y + 91, cardset.name, optionsStyle());
    nameText.fontSize = 24;
    this.modalContents.addChild(nameText);

    x += 130;
    var cardStart = x;

    var set = this.state.createSelectorSet(
      cardset.card_count_type, cardset.card_count_value, 
      (valid: boolean) => { cardInstructions.fill = valid ? '#00ff00' : '#ff0000'; },
      (card: Card, view: SpriteView) => {
        console.log("HELLO WORLD");
        if (card.marked)
          view.sprite.loadTexture('card_face_selected', 0);
        else
          view.sprite.loadTexture('card_face_empty', 0);
      });

    cardset.cards.forEach((c) => {
      var view = this.createCardView(c, this.modalContents, false, x, y);
      view.sprite.events.onInputDown.add(set.add(c, view), this);
      x += Util.CardPadded;
      if (x > (1100 - Util.CardPadded)) {
        x = cardStart;
        y += Util.CardHeightPadded;
      }
    });

    set.finishedAdding();

    y += 30;
    x += 60;

    if (x > 900) {
      x = cardStart;
      y += Util.CardHeightPadded;
    }


    var optSet = this.state.createSelectorSet(
      cardset.option_count_type, cardset.option_count_value,
      (valid: boolean) => { optInstructions.fill = valid ? '#00ff00' : '#ff0000'; },
      (checkbox: Markable, view: SpriteView) => {
        if (checkbox.marked)
          view.sprite.animations.frame = 0;
        else
          view.sprite.animations.frame = 1;
      });


    for (var opt in cardset.options) {
      var view = this.createView('checkbox', cardset.options[opt], this.modalContents, x, y, optionsStyle());
      view.sprite.animations.frame = 1;
      var obj = {id: opt, marked: false};
      view.sprite.events.onInputDown.add(optSet.add(obj, view), this);
      y += 34;
    }

    optSet.finishedAdding();

    set.validate();
    optSet.validate();

    cardset.cardsResult = set;
    cardset.optionsResult = optSet;

  }

  drawCardsetOptions = () => {
    var raw = this.state.currentModal;
    var cardsets: Array<CardsetOption> = raw.get('cardsets');

    var graphics:any = this.game.add.graphics(0, 0);
    graphics.inputEnabled = true;

    graphics.lineStyle(2, 0x000000, 1);


		for (var i = 0; i < cardsets.length; i++) {
      this.drawCardset(graphics, cardsets[i], 40, i * 200);
    }

    this.modalContents.addChild(graphics);
  }

  drawModal = () => {
    if (this.state.modalEnabled) {
      this.modalContents.removeAll(true, true);
      switch (this.state.drawModal) {
        case 'cardset_options':
          this.drawCardsetOptions();
          break;
      }
      this.game.world.bringToTop(this.modalDialog);
      this.modalDialog.visible = true;
    } else {
      this.modalDialog.visible = false;
    }
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

    this.drawModal();

  }

  create = () => {
    this.game.stage.backgroundColor = 0xefefef;
    this.turnIndicator = this.game.add.text(0, 20, "Phase: ???", {font: "14px Arial"});
    this.currentPlayerStatus = this.game.add.text(0, 40, "Status: ???", {font: "14px Arial"});

    this.modalDialog = this.game.add.group();
    this.modalDialog.x = 50;
    this.modalDialog.y = 50;
    this.modalDialog.visible = false;
    this.modalContents = this.game.add.group();

    var dialogBG = this.game.add.tileSprite(0, 0, 1100, 800, 'dialog_bg');
    dialogBG.inputEnabled = true;
    this.modalDialog.addChild(this.modalContents);
    this.modalDialog.addChild(dialogBG);
    this.modalDialog.sendToBack(dialogBG);

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

//comment = 17

