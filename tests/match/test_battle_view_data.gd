extends TestCase
## Snapshot data the battle screen needs (issue #25): full round order,
## enemy Speed for the initiative timeline and EXP to the next level.

var h: MatchHarness
var sessions: Array[int] = []


func before_each() -> void:
	h = MatchHarness.new(7, MatchHarness.merge([MatchHarness.ALL_COMBAT, MatchHarness.WOLF_PAIR,
			MatchHarness.EXACT_DAMAGE]))
	sessions = h.start_with_humans(1)
	h.enter_first_encounter(sessions)


func test_combat_view_carries_the_whole_round_order() -> void:
	var combat: Dictionary = h.match_view(sessions[0])["encounter"]
	assert_eq(combat["round_order"], ["e0", "e1", "p0", "p1", "p2", "p3", "p4"], "wolves (SPD 13) before the Party (SPD 10)")


func test_enemy_views_carry_speed() -> void:
	var combat: Dictionary = h.match_view(sessions[0])["encounter"]
	assert_eq(combat["enemies"][0]["spd"], 13)


func test_party_view_carries_exp_to_next_level() -> void:
	var me: Dictionary = h.match_view(sessions[0])["party"][0]
	assert_eq([me["level"], me["exp"], me["exp_next"]], [1, 0, 20])


func test_party_view_carries_crit_for_the_camp_stat_sheet() -> void:
	var me: Dictionary = h.match_view(sessions[0])["party"][0]
	assert_eq(me["crit"], 0.0, "Classless crit pinned to 0 by EXACT_DAMAGE")
