class_name MerchantEncounter
extends Encounter
## Merchant: any human may buy Items with the Party's shared Gold. The shop
## closes when every human has said they are ready to move on, or when its
## timer runs out; nobody has to buy anything. AI-controlled slots never buy.
##
## Commands: buy {item}   ready

var stock: Array[Dictionary] = []
var ready_slots: Array[int] = []
var deadline := -1.0


func start(run: MatchRun) -> void:
	for entry in run.content.get_array("encounters.merchant.stock"):
		var item := str(entry["item"])
		stock.append({"item": item, "remaining": int(entry.get("quantity", 1)),
				"price": run.content.get_int("items.%s.price" % item)})
	deadline = run.clock.now() + run.content.get_float("encounters.merchant.seconds", 45.0)
	run.emit({"type": "merchant_opened", "stock": _stock_view(run), "deadline": deadline})


func handle(run: MatchRun, slot: int, cmd: Dictionary) -> Dictionary:
	match str(cmd.get("type", "")):
		"buy":
			return _buy(run, slot, str(cmd.get("item", "")))
		"ready":
			if ready_slots.has(slot):
				return {"ok": false, "error": "already_ready"}
			ready_slots.append(slot)
			run.emit({"type": "merchant_ready", "slot": slot})
			_close_if_everyone_ready(run)
			return {"ok": true}
	return {"ok": false, "error": "wrong_phase"}


func update(run: MatchRun) -> void:
	if not done and run.clock.now() >= deadline:
		_close(run)


func on_control_changed(run: MatchRun, _slot: int) -> void:
	_close_if_everyone_ready(run)


func view(run: MatchRun, viewer_slot: int) -> Dictionary:
	return {
		"kind": "merchant",
		"greeting": str(run.content.get_value("encounters.merchant.greeting", "")),
		"stock": _stock_view(run),
		"ready": ready_slots.duplicate(),
		"humans": _human_count(run),
		"you_are_ready": ready_slots.has(viewer_slot),
		"deadline": deadline,
	}


func _buy(run: MatchRun, slot: int, item: String) -> Dictionary:
	var entry := {}
	for candidate in stock:
		if candidate["item"] == item:
			entry = candidate
	if entry.is_empty():
		return {"ok": false, "error": "invalid_item"}
	if int(entry["remaining"]) <= 0:
		return {"ok": false, "error": "out_of_stock"}
	if run.gold < int(entry["price"]):
		return {"ok": false, "error": "not_enough_gold"}
	run.add_gold(-int(entry["price"]))
	entry["remaining"] = int(entry["remaining"]) - 1
	run.add_item(item, 1)
	run.emit({"type": "purchase", "slot": slot, "item": item, "price": entry["price"], "gold": run.gold})
	return {"ok": true, "gold": run.gold}


func _human_count(run: MatchRun) -> int:
	var count := 0
	for slot in run.humans().size():
		if run.is_human(slot):
			count += 1
	return count


func _close_if_everyone_ready(run: MatchRun) -> void:
	if done:
		return
	for slot in run.humans().size():
		if run.is_human(slot) and not ready_slots.has(slot):
			return
	_close(run)


func _close(run: MatchRun) -> void:
	done = true
	run.emit({"type": "merchant_closed"})


func _stock_view(run: MatchRun) -> Array:
	var out: Array = []
	for entry in stock:
		var data := run.content.get_dict("items.%s" % entry["item"])
		out.append({
			"item": entry["item"],
			"name": str(data.get("name", entry["item"])),
			"description": str(data.get("description", "")),
			"price": entry["price"],
			"remaining": entry["remaining"],
			"affordable": run.gold >= int(entry["price"]) and int(entry["remaining"]) > 0,
		})
	return out
