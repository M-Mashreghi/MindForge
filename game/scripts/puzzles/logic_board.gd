extends RefCounted
## The player's current arrangement for an ordering logic puzzle. Pure UI
## state: it knows nothing about clues or the solver.

signal changed

var items: Array = []
## One entry per slot: an item id or "" when empty.
var slots: Array = []


func _init(item_ids: Array = []) -> void:
	items = item_ids.duplicate()
	reset()


func reset() -> void:
	slots = []
	slots.resize(items.size())
	slots.fill("")
	changed.emit()


## Puts `item` in `slot`, or in the first empty slot when `slot` is -1.
## An item already placed elsewhere moves. Returns false if nothing changed.
func place(item: String, slot: int = -1) -> bool:
	if not item in items:
		return false
	if slot < 0:
		slot = slots.find("")
		if slot < 0:
			return false
	if slot >= slots.size():
		return false
	var previous := slots.find(item)
	if previous >= 0:
		slots[previous] = ""
	slots[slot] = item
	changed.emit()
	return true


func clear_slot(slot: int) -> void:
	if slot >= 0 and slot < slots.size() and slots[slot] != "":
		slots[slot] = ""
		changed.emit()


func is_placed(item: String) -> bool:
	return item in slots


func is_complete() -> bool:
	return not "" in slots


func order() -> Array:
	return slots.duplicate()
