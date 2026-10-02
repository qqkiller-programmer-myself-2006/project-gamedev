extends TestCase
## Regression test for 3D QA harness and performance tools (T3D-05).

const QA3D_PERF_SCRIPT := "res://tools/dev/qa3d_perf.gd"


func test_qa3d_perf_script_loads_and_instantiates() -> void:
	var script = load(QA3D_PERF_SCRIPT)
	assert_true(script != null, "qa3d_perf.gd must exist and load successfully")
	assert_true(script.can_instantiate(), "qa3d_perf.gd must be instantiable")


func test_qa3d_perf_computes_statistics_accurately() -> void:
	var script = load(QA3D_PERF_SCRIPT)
	var instance = script.new()
	assert_true(instance != null, "qa3d_perf instance should not be null")

	# Verify integer helper functions
	var sample_ints: Array[int] = [10, 20, 30, 40, 50]
	assert_eq(instance._average_int(sample_ints), 30, "average_int calculation")
	assert_eq(instance._max_int(sample_ints), 50, "max_int calculation")
	assert_eq(instance._average_int([]), 0, "empty array average")
	assert_eq(instance._max_int([]), 0, "empty array max")

	instance.free()
