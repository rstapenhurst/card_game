/// <reference path="phaser.d.ts" />
/// <reference path="jquery.d.ts" />
/// <reference path="card_game_interfaces.d.ts" />
/// <reference path="game_state.js.ts" />

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


}
