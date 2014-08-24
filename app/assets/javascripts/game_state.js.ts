/// <reference path="phaser.d.ts" />
/// <reference path="jquery.d.ts" />
/// <reference path="card_game_interfaces.d.ts" />


function doNothing() { }

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

class ClientState {
  gameState: GameState;
  dirty: ClientDirtyBits;
  instructions: string;

  modalEnabled: boolean;
  currentModal: any;
  drawModal: string;

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
      case 'cardset_options':
        this.currentModal = raw;
        this.drawModal = 'cardset_options';
        this.modalEnabled = true;
        this.setFunctions(doNothing, function(game) {
          var cardsets: Array<CardsetOption> = raw.get('cardsets');
          var results = [];

          for (var i = 0; i < cardsets.length; i++) {
            var c = {
              id: cardsets[i].id,
              cards: [],
              options: []
            };

            results.push(c);

            if (cardsets[i].cardsResult.valid() && cardsets[i].optionsResult.valid()) {
              var cards 

              c.cards = cardsets[i].cardsResult.results(); 
              c.options = cardsets[i].optionsResult.results();
            } else {
              return;
            }

            game.trigger('dialog_respond_event', {dialog_id: raw.get('id'), cardsets: results});
            this.setInstructions("Waiting for players...");
            this.setFunctions(doNothing, doNothing);
            this.modalEnabled = false;
            game.drawModal();
          }
        });
        break;
      case 'choose_cards':
        this.setInstructions(raw.get('prompt'));
        this.handleChooseCards(<ChooseCards>raw);
        break;
      default:
        console.log("Unknown dialog: " + JSON.stringify(raw));
        break;
    }
  }

  createSelectorSet(count_type: string, count_value: number, doValidate: Function, onChange: Function) {
    var selected = { length: 0 };
    var allSet: Array<{value: Markable; view: any; change: Function}> = [];
    return {
      results: function() {
        var ids = [];
        delete selected['length']
        for (var key in selected) {
          ids.push(key);
        }
        console.log("Hello");
        return ids;
      },
      valid: function() {
        return FilterComplete[count_type](selected, count_value);
      },
      validate: function() {
        doValidate(FilterComplete[count_type](selected, count_value));
      },
      add: function(value: Markable, view: any) {
        var onClick = function() {
          if (selected.hasOwnProperty('' + value.id)) {
            delete selected['' + value.id]
            selected['length']--;
            value.marked = false;
            onChange(value, view);
            doValidate(FilterComplete[count_type](selected, count_value));
          } else {
            if (FilterSelect[count_type](selected, value, count_value)) {
              selected['' + value.id] = true;
              value.marked = true;
              selected['length']++;
              onChange(value, view);
              doValidate(FilterComplete[count_type](selected, count_value));
            }
          }
        };
        allSet.push({value: value, view: view, change: onClick});
        return onClick;
      },
      finishedAdding: function() {
        if (count_type == 'exactly' && (count_value == allSet.length)) {
          allSet.forEach(function(marky) {
            marky.change();
          });
        }
      }
    };
  }

  handleChooseCards(event: ChooseCards) {
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
