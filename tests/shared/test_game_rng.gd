extends TestCase


func test_same_seed_gives_same_sequence() -> void:
	var a := GameRng.new(42)
	var b := GameRng.new(42)
	var seq_a := []
	var seq_b := []
	for i in 20:
		seq_a.append(a.randi_range(0, 1000))
		seq_b.append(b.randi_range(0, 1000))
	assert_eq(seq_a, seq_b)


func test_different_seeds_give_different_sequences() -> void:
	var a := GameRng.new(1)
	var b := GameRng.new(2)
	var seq_a := []
	var seq_b := []
	for i in 20:
		seq_a.append(a.randi_range(0, 1000))
		seq_b.append(b.randi_range(0, 1000))
	assert_ne(seq_a, seq_b)


func test_fork_is_reproducible() -> void:
	var a := GameRng.new(7).fork()
	var b := GameRng.new(7).fork()
	assert_eq(a.randi_range(0, 1_000_000), b.randi_range(0, 1_000_000))


func test_shuffled_keeps_every_element() -> void:
	var rng := GameRng.new(3)
	var items := [1, 2, 3, 4, 5, 6]
	var out := rng.shuffled(items)
	out.sort()
	assert_eq(out, items)
	assert_eq(items, [1, 2, 3, 4, 5, 6], "original array untouched")


func test_weighted_index_never_picks_zero_weight() -> void:
	var rng := GameRng.new(9)
	for i in 200:
		assert_ne(rng.weighted_index([0, 1, 0, 3]), 0)
	assert_eq(rng.weighted_index([0, 0]), -1)
