class_name UiText
extends RefCounted
## Every piece of client UI text in one place (ADR-0007): error messages,
## Encounter type labels and short explanations used by hints.

const ERRORS := {
	"profile_unavailable": "Your profile could not be loaded. Progress will not be saved this session.",
	"profile_changed_elsewhere": "Your profile changed in another session. This session's latest progress was not saved. Rejoin to refresh it.",
	"profile_save_failed": "Your profile could not be saved. Rejoin and check your progress before continuing.",
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
	"unsupported_encounter": "The route led somewhere the game does not know. The Match was stopped.",
	"not_your_turn": "It is not your turn.",
	"not_your_slot": "That character is not yours.",
	"action_window_closed": "Too late: your turn ran out and you Defended.",
	"invalid_action": "That action is not available.",
	"invalid_target": "Pick one of the highlighted targets.",
	"item_unavailable": "The Party has none of that Item left.",
	"skill_unavailable": "No Skill yet. Find a Class at a Class Encounter first.",
	"skill_on_cooldown": "That Skill is still cooling down.",
	"not_enough_energy": "Not enough Energy. Attack, Defend or wait a turn to regain it.",
	"invalid_option": "That choice does not exist.",
	"already_voted": "You already voted.",
	"ai_cannot_vote": "AI-controlled characters do not vote.",
	"not_enough_gold": "The Party does not have enough Gold.",
	"out_of_stock": "Sold out.",
	"invalid_item": "The merchant does not sell that.",
	"already_ready": "You are already marked as ready.",
	"not_eligible": "Your character cannot take this Class.",
	"item_unusable": "That is not something you can use in a fight.",
	"invalid_recipe": "There is no such recipe.",
	"missing_materials": "The shared bag does not hold enough materials for that.",
	"not_gear": "That is not gear.",
	"wrong_gear_slot": "That gear does not go in that slot.",
	"nothing_equipped": "Nothing is worn there.",
	"no_points": "No stat points left to spend.",
	"invalid_stat": "Points cannot go into that stat.",
	"already_decided": "You already answered.",
	"unknown_command": "The server did not understand that.",
	"unknown_session": "Your session expired. Please reconnect.",
	"dev_offline_only": "Developer shortcuts only work in the local Playtest.",
	"invalid_jump": "That Playtest jump does not exist.",
	"story_offline_only": "Story mode is an offline journey. Play alone or over Local Network.",
	"invalid_save": "This story save file is broken or from a different version.",
	"old_save": "This save is from an older build.",
	"bad_message": "The server did not understand that.",
	"cannot_connect": "Could not reach the server. Check the address and try again.",
	"connect_timeout": "The server did not answer in time. Check the address and try again.",
	"connection_lost": "The connection to the server was lost.",
	"server_stopping": "The server is shutting down.",
	"invalid_class": "Choose one of the available Classes.",
	"race_not_owned": "Purchase this Race before selecting it.",
	"invalid_race": "That Race is unavailable.",
	"already_owned": "You already own this Race.",
	"not_enough_gems": "You do not have enough Gems.",
	"invalid_boon": "That Boon is unavailable.",
	"over_capacity": "Those Boons use more than five slots.",
	"locked": "This choice is still locked.",
	"invalid_node": "That Skill Tree node is unavailable.",
	"max_level": "This node is already at level 5.",
	"max_prestige": "This Class has reached maximum Prestige.",
	"invalid_slot": "That character slot does not exist.",
	"invalid_loadout": "That Race, Class or Boon choice is not allowed.",
	"invalid_amount": "Enter an amount of at least 1.",
	"invalid_token": "Your profile could not be verified. Restart the game and try again.",
	"not_consumable": "That Item cannot be used.",
	"not_in_stash": "The shared bag does not hold that Item.",
	"nothing_to_reset": "No Skill Tree levels to reset for this Class.",
	"handshake_timeout": "The server did not answer in time. Check the address and try again.",
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
	"merchant": "Spend your own Gold on Items; each character buys with their own.",
	"rest": "Recover HP, craft gear and spend stat points.",
	"treasure": "Free Gold or Items.",
	"story": "A clue about Father's journey.",
	"class": "A Challenge that can teach a new Class.",
}

const HINTS := {
	"vote": "Path Voting: every player has one vote and AI never votes. The most votes wins; ties are broken at random. Press 1-3 to vote.",
	"combat": "Your turn! Fight [F] opens your attacks, Items [I] uses your personal Gold and consumable slot, and Focus [O] restores Energy when available. In timed Combats you have 15 seconds; if time runs out you Defend.",
	"combat_story": "Your turn! Fight [F] opens your attacks, Items [I] uses your personal Gold and consumable slot, and Focus [O] restores Energy when available. Story turns have no countdown.",
	"skill": "You have a Class now. Fight [F] opens your Skills; each Skill costs Energy and has a cooldown counted in your own turns.",
	"class_offer": "Accept [Y] to take this Class, or Decline [N] to stay Classless and wait for another. Several characters can share a Class.",
	"merchant": "Each character buys with their own Gold, and you can Transfer Gold to a friend. Press [R] when you are done; the shop closes when everyone is ready.",
	"energy": "Energy (the blue bar) pays for Skills: you start each Combat with 1 and regain 1 every later turn, up to 6. Strike, Guard, Focus and Items are free.",
	"dot": "DoTs (Bleed BLD, Poison PSN, Toxin TOX) hurt at the start of each of their holder's turns, ignoring armour. The badge shows stacks (x) and turns left (t).",
	"rest": "Camp: craft from materials on the left, equip gear from the shared bag in the middle, and spend stat points on the right. Press [R] when you are done; the camp moves on when every player is Ready.",
	"boss": "Watch the warnings: the Guardian announces its heaviest blows a turn early. Defend, Protect or raise Shield Wall before they land.",
}

## Destructive actions ask first: [title, text, confirm button].
const CONFIRM := {
	"leave_room": ["Leave the room?", "You go back to the title screen. Your slot is played by AI until someone takes it.", "Leave room"],
	"leave_match": ["Leave the Match?", "You go back to the title screen and your character is played by AI for the rest of this Match.", "Leave Match"],
	"reset_skills": ["Reset Skills?", "Every Skill Tree level of the %s Class goes back to 0. This costs %d Gems.", "Reset Skills"],
}

## Small labels and tooltips shared by several screens.
const LABELS := {
	"connecting": "Connecting to %s ...",
	"got_it": "Got it [H]",
	"continue": "Continue [Enter]",
	"chapter": "Chapter %d",
	"dialogue_hint": "> Next [Enter]     Skip [Esc]",
	"menu_tip": "Menu [Esc]",
	"clues_tip": "Clues [C]",
	"action_window": "Action window",
	"gold": "%d Gold",
	"gems": "%d Gems",
}

## Empty states: what the player can do next.
const EMPTY := {
	"inventory": "The shared bag is empty. Win fights, open Treasure or buy from a Merchant to fill it.",
	"stash": "Nothing in the stash yet. Items you find land here.",
	"recipes": "No recipes to craft right now. Gather materials in fights first.",
	"shop": "The Merchant has nothing left to sell.",
	"search": "Nothing matches \"%s\". Clear the search to see everything.",
	"boons": "No Boons equipped. Pick one from the middle column.",
	"records": "No records yet. Finish a Match to start your history.",
	"clues": "No clues yet. Story Events (and some fights) reveal where Father went.",
}

## Why a control is disabled (shown in its tooltip).
const WHY := {
	"voted": "You already voted. Waiting for the others.",
	"ready": "You are ready. Waiting for the other players.",
	"no_items": "The shared bag has no Item you can use now.",
	"max_level": "This node is already at level 5.",
	"need_gems": "Not enough Gems: this costs %d, you have %d.",
	"prestige_locked": "Raise every Skill Tree node to 5/5 first.",
	"prestige_max": "This Class has reached maximum Prestige.",
	"invest_merchant": "Spend stat points at a Rest camp.",
	"invest_none": "No stat points to spend. Level up to earn more.",
	"invest_not_yours": "You can only spend your own character's points.",
	"equip_not_yours": "You can only change your own character's gear.",
	"sold_out": "Sold out.",
	"need_gold": "Not enough Gold: this costs %d.",
	"focus_unavailable": "Focus is not available right now.",
	"focus_ready": "Gain Energy and Dodge this turn.",
	"transfer_unavailable": "Only a character carrying Gold can transfer it.",
}

const STORY_TRIGGERS := ["first_combat_won", "class_gained", "story_clue", "merchant_first", "rest_first", "before_boss", "boss_won", "party_defeated"]


static func error(code: String) -> String:
	return str(ERRORS.get(code, "Something went wrong (%s)." % code))


static func gems(amount: int) -> String:
	return LABELS["gems"] % amount


static func gold(amount: int) -> String:
	return LABELS["gold"] % amount


static func type_label(type: String) -> String:
	return str(TYPE_LABELS.get(type, type.capitalize()))


static func type_tag(type: String) -> String:
	return str(TYPE_TAGS.get(type, type.to_upper()))


## Region name for a Layer (or the Boss) from `journey.regions` / `boss.region`;
## falls back to "Forest" (T29: Layer 5 and the Boss are in the Cave).
static func region_name(content: Dictionary, layer: int, boss: bool = false) -> String:
	if boss:
		var boss_region := str(content.get("boss", {}).get("region", ""))
		if not boss_region.is_empty():
			return boss_region
	var region := str(content.get("journey", {}).get("regions", {}).get(str(layer), ""))
	return region if not region.is_empty() else "Forest"


static var _content_cache: Dictionary = {}


## Region name for a Match snapshot, read from the default Forest content.
static func region_of(view: Dictionary) -> String:
	if _content_cache.is_empty():
		_content_cache = ForestContent.load_default().data
	var encounter = view.get("encounter")
	var boss := str(view.get("phase", "")) == "boss" or (encounter is Dictionary and str(encounter.get("kind", "")) == "boss")
	return region_name(_content_cache, int(view.get("layer", 0)), boss)


## Class display name: the content `name`, else the id capitalised.
static func class_display(classes: Dictionary, class_id: String) -> String:
	var entry = classes.get(class_id, {})
	var display := str(entry.get("name", "")) if entry is Dictionary else ""
	return display if not display.is_empty() else class_id.capitalize()


static func clock(seconds: float) -> String:
	var total := maxi(0, int(round(seconds)))
	return "%d:%02d" % [total / 60, total % 60]
