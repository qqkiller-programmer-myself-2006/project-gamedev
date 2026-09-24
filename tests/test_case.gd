class_name TestCase
extends RefCounted
## Base class for tests run by tests/run_tests.gd.
##
## Every method whose name starts with `test_` is a test. The runner creates
## a fresh instance per test, calls before_each() if it exists, then the
## test method. Assertions record failures instead of stopping the test, and
## any engine or script error raised while the test runs also fails it.

var _failures: Array[String] = []


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail(_label(message, "expected true"))


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail(_label(message, "expected false"))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _equal(actual, expected):
		fail(_label(message, "expected %s but got %s" % [_show(expected), _show(actual)]))


func assert_ne(actual: Variant, not_expected: Variant, message: String = "") -> void:
	if _equal(actual, not_expected):
		fail(_label(message, "did not expect %s" % _show(actual)))


func assert_has(container: Variant, item: Variant, message: String = "") -> void:
	var found := false
	if container is Dictionary:
		found = container.has(item)
	elif container is Array or container is String:
		found = container.has(item) if container is Array else container.contains(str(item))
	if not found:
		fail(_label(message, "%s does not contain %s" % [_show(container), _show(item)]))


func assert_not_has(container: Variant, item: Variant, message: String = "") -> void:
	var found := false
	if container is Dictionary or container is Array:
		found = container.has(item)
	elif container is String:
		found = container.contains(str(item))
	if found:
		fail(_label(message, "%s unexpectedly contains %s" % [_show(container), _show(item)]))


func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	if value < low or value > high:
		fail(_label(message, "expected %s to be within [%s, %s]" % [value, low, high]))


## Asserts a MatchServer command result was accepted.
func assert_ok(result: Dictionary, message: String = "") -> void:
	if not result.get("ok", false):
		fail(_label(message, "command rejected: %s" % _show(result)))


## Asserts a MatchServer command result was rejected with `error`.
func assert_rejected(result: Dictionary, error: String, message: String = "") -> void:
	if result.get("ok", false):
		fail(_label(message, "expected rejection '%s' but command was accepted" % error))
	elif str(result.get("error", "")) != error:
		fail(_label(message, "expected error '%s' but got '%s'" % [error, result.get("error")]))


func _label(message: String, detail: String) -> String:
	return detail if message.is_empty() else "%s: %s" % [message, detail]


static func _show(value: Variant) -> String:
	if value is String:
		return "\"%s\"" % value
	return str(value)


## Structural equality that never raises on mismatched types and treats
## 3 and 3.0 as equal (JSON content numbers are floats).
static func _equal(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if ta in numeric and tb in numeric:
		return is_equal_approx(float(a), float(b))
	if ta != tb:
		if (ta == TYPE_STRING or ta == TYPE_STRING_NAME) and (tb == TYPE_STRING or tb == TYPE_STRING_NAME):
			return str(a) == str(b)
		return false
	if ta == TYPE_ARRAY:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _equal(a[i], b[i]):
				return false
		return true
	if ta == TYPE_DICTIONARY:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not _equal(a[key], b[key]):
				return false
		return true
	return a == b
