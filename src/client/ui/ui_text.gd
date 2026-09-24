class_name UiText
extends RefCounted
## Every piece of client UI text in one place (ADR-0007): error messages,
## Encounter type labels and short explanations used by hints.

const ERRORS := {
	"invalid_name": "Please enter a display name.",
	"invalid_code": "Room codes are 6 letters or numbers, like K7PQ2M.",
	"room_not_found": "No room uses that code. Check it with your friend.",
	"room_closed": "That room has closed.",
	"room_full": "That room is full: all 5 slots have players.",
	"match_in_progress": "That room is in the middle of a Match. Try again when it ends.",
	"already_in_room": "You are already in a room.",
	"not_in_room": "You are not in a room.",
	"not_host": "Only the Host can start the Match.",
	"wrong_phase": "That can't be done right now.",
	"not_your_turn": "It is not your turn.",
	"not_your_slot": "That character is not yours.",
	"action_window_closed": "Too late: your turn ran out and you Defended.",
	"invalid_action": "That action is not available.",
	"invalid_target": "Pick one of the highlighted targets.",
	"item_unavailable": "The Party has none of that Item left.",
	"skill_unavailable": "No Skill yet. Find a Class at a Class Encounter first.",
	"skill_on_cooldown": "That Skill is still cooling down.",
	"invalid_option": "That choice does not exist.",
	"already_voted": "You already voted.",
	"ai_cannot_vote": "AI-controlled characters do not vote.",
	"not_enough_gold": "The Party does not have enough Gold.",
	"out_of_stock": "Sold out.",
	"invalid_item": "The merchant does not sell that.",
	"already_ready": "You are already marked as ready.",
	"not_eligible": "Your character cannot take this Class.",
	"already_decided": "You already answered.",
	"unknown_command": "The server did not understand that.",
	"unknown_session": "Your session expired. Please reconnect.",
	"bad_message": "The server did not understand that.",
	"cannot_connect": "Could not reach the server. Check the address and try again.",
	"connection_lost": "The connection to the server was lost.",
	"server_stopping": "The server is shutting down.",
}

const TYPE_LABELS := {
	"combat": "Combat", "merchant": "Merchant", "rest": "Rest", "treasure": "Treasure",
	"story": "Story Event", "class": "Class Encounter", "boss": "Guardian Boss", "choice": "Choice",
}

## Short text tags so Encounter types never rely on colour.
const TYPE_TAGS := {
	"combat": "FIGHT", "merchant": "SHOP", "rest": "REST", "treasure": "LOOT",
	"story": "STORY", "class": "CLASS", "boss": "BOSS", "choice": "CHOICE",
}

const TYPE_HELP := {
	"combat": "A fight for EXP, Gold and maybe Items.",
	"merchant": "Spend the Party's shared Gold on Items.",
	"rest": "Recover HP before harder fights.",
	"treasure": "Free Gold or Items.",
	"story": "A clue about Father's journey.",
	"class": "A Challenge that can teach a new Class.",
}

const HINTS := {
	"vote": "Path Voting: every player has one vote and AI never votes. The most votes wins; ties are broken at random. Press 1-3 to vote.",
	"combat": "Your turn! [A] Attack, [S] Skill (needs a Class), [D] Defend halves damage until your next turn, [I] Item uses the Party's shared bag. You have 15 seconds; if time runs out you Defend.",
	"skill": "You have a Class now. [S] opens your Skills; each Skill has a cooldown counted in your own turns.",
	"class_offer": "Accept [Y] to take this Class, or Decline [N] to stay Classless and wait for another. Several characters can share a Class.",
	"merchant": "Anyone can buy with the Party's shared Gold. Press [R] when you are done; the shop closes when everyone is ready.",
	"boss": "Watch the warnings: the Guardian announces its heaviest blows a turn early. Defend, Protect or raise Shield Wall before they land.",
}


static func error(code: String) -> String:
	return str(ERRORS.get(code, "Something went wrong (%s)." % code))


static func type_label(type: String) -> String:
	return str(TYPE_LABELS.get(type, type.capitalize()))


static func type_tag(type: String) -> String:
	return str(TYPE_TAGS.get(type, type.to_upper()))


static func clock(seconds: float) -> String:
	var total := maxi(0, int(round(seconds)))
	return "%d:%02d" % [total / 60, total % 60]
