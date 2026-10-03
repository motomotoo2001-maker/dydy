extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("SELECTION_FEEDBACK_FAIL: " + message)
	quit(2)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene missing")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var arena := scene.get_node_or_null("ArenaBuilder") as ArenaBuilder
	if arena == null:
		_fail("ArenaBuilder missing")
		return

	var moves: Array[Dictionary] = [
		{"from": &"E2", "to": &"E3"},
		{"from": &"E2", "to": &"D3", "capture": true},
		{"from": &"E1", "to": &"G1", "castle": &"king"},
		{"from": &"E7", "to": &"E8", "promotion": &"Queen"},
		{"from": &"E7", "to": &"E8", "promotion": &"Rook"},
		{"from": &"E7", "to": &"E8", "promotion": &"Bishop"},
		{"from": &"E7", "to": &"E8", "promotion": &"Knight"},
	]
	arena.show_selection(&"E2", moves)
	await process_frame

	if arena.find_child("MoveMarkerDisc_E3", true, false) == null:
		_fail("ordinary move disc missing")
		return
	if arena.find_child("MoveMarkerRing_D3", true, false) == null:
		_fail("capture ring missing")
		return
	if arena.find_child("MoveMarkerDiamond_G1", true, false) == null:
		_fail("castling diamond missing")
		return
	if arena.find_child("MoveMarkerRing_E8", true, false) == null:
		_fail("promotion ring missing")
		return
	if arena.find_child("MoveMarkerDiamond_E8", true, false) == null:
		_fail("promotion diamond missing")
		return

	var promotion_rings := 0
	var promotion_diamonds := 0
	for child in arena.selection_root.get_children():
		if String(child.name) == "MoveMarkerRing_E8":
			promotion_rings += 1
		elif String(child.name) == "MoveMarkerDiamond_E8":
			promotion_diamonds += 1
	if promotion_rings != 1 or promotion_diamonds != 1:
		_fail("promotion variants were not deduplicated")
		return

	arena.clear_selection()
	await process_frame
	if arena.find_child("MoveMarkerDisc_E3", true, false) != null:
		_fail("selection markers were not cleared")
		return

	print("SELECTION_FEEDBACK_PASS disc capture_ring castle_diamond promotion_combo")
	scene.queue_free()
	await process_frame
	quit(0)
