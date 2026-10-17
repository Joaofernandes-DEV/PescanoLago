extends GdUnitTestSuite
## Testes do Rng (xoshiro128**). Os valores esperados vêm de uma implementação
## de referência independente em Python com inteiros sem limite de tamanho.


func test_known_vector_from_state_1_2_3_4() -> void:
	var rng := Rng.new()
	rng.set_state(PackedInt64Array([1, 2, 3, 4]))
	var outputs: Array[int] = []
	for i in 6:
		outputs.append(rng.next_u32())
	assert_array(outputs).is_equal([11520, 0, 5927040, 70819200, 2031721883, 1637235492])


func test_seed_expansion_matches_reference() -> void:
	assert_array(Array(Rng.new(0).get_state())).is_equal(
		[2462723854, 1020716019, 454327756, 1275600319]
	)
	assert_array(Array(Rng.new(42).get_state())).is_equal(
		[939911724, 3948730756, 321366731, 3317318717]
	)
	assert_array(Array(Rng.new(-7).get_state())).is_equal(
		[2058230478, 4058419463, 2597089134, 3701374811]
	)


func test_sequence_from_seed_matches_reference() -> void:
	var rng := Rng.new(20261017)
	var outputs: Array[int] = []
	for i in 5:
		outputs.append(rng.next_u32())
	assert_array(outputs).is_equal([3483368407, 2963673981, 1267004664, 911733163, 2119709544])


func test_same_seed_gives_same_sequence() -> void:
	var a := Rng.new(123456789)
	var b := Rng.new(123456789)
	for i in 1000:
		assert_int(a.next_u32()).is_equal(b.next_u32())


func test_different_seeds_give_different_sequences() -> void:
	assert_int(Rng.new(1).next_u32()).is_not_equal(Rng.new(2).next_u32())


func test_state_round_trip_resumes_sequence() -> void:
	var rng := Rng.new(99)
	for i in 10:
		rng.next_u32()
	var saved := rng.get_state()
	var expected := rng.next_u32()
	var restored := Rng.new()
	restored.set_state(saved)
	assert_int(restored.next_u32()).is_equal(expected)


func test_get_state_returns_a_copy() -> void:
	var rng := Rng.new(5)
	var state := rng.get_state()
	state[0] = 0
	assert_int(rng.get_state()[0]).is_not_equal(0)


func test_next_u32_stays_in_32_bits() -> void:
	var rng := Rng.new(7)
	for i in 10000:
		var value := rng.next_u32()
		assert_bool(value >= 0 and value <= Rng.MASK_32).is_true()


func test_next_float_in_unit_interval() -> void:
	var rng := Rng.new(8)
	for i in 10000:
		var value := rng.next_float()
		assert_bool(value >= 0.0 and value < 1.0).is_true()


func test_range_int_covers_bounds_and_stays_inside() -> void:
	var rng := Rng.new(9)
	var seen := {}
	for i in 5000:
		var value := rng.range_int(-2, 3)
		assert_bool(value >= -2 and value <= 3).is_true()
		seen[value] = true
	assert_int(seen.size()).is_equal(6)


func test_range_int_single_value() -> void:
	assert_int(Rng.new(10).range_int(4, 4)).is_equal(4)


func test_range_int_is_roughly_uniform() -> void:
	var rng := Rng.new(11)
	var counts := [0, 0, 0, 0]
	for i in 40000:
		counts[rng.range_int(0, 3)] += 1
	for c: int in counts:
		assert_int(c).is_between(9500, 10500)


func test_chance_extremes() -> void:
	var rng := Rng.new(12)
	for i in 1000:
		assert_bool(rng.chance(0.0)).is_false()
		assert_bool(rng.chance(1.0)).is_true()


func test_chance_frequency() -> void:
	var rng := Rng.new(13)
	var hits := 0
	for i in 100000:
		if rng.chance(0.02):
			hits += 1
	assert_int(hits).is_between(1800, 2200)


func test_weighted_index_respects_weights() -> void:
	var rng := Rng.new(14)
	var counts := [0, 0, 0]
	for i in 30000:
		counts[rng.weighted_index(PackedFloat64Array([1.0, 0.0, 2.0]))] += 1
	assert_int(counts[1]).is_equal(0)
	assert_int(counts[0]).is_between(9400, 10600)
	assert_int(counts[2]).is_between(19400, 20600)


func test_weighted_index_without_positive_weight() -> void:
	assert_int(Rng.new(15).weighted_index(PackedFloat64Array([0.0, -1.0]))).is_equal(-1)
	assert_int(Rng.new(15).weighted_index(PackedFloat64Array())).is_equal(-1)
