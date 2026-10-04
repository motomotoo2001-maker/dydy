extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("TACTICAL_FEEDBACK_FAIL: " + message)
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

	var synthetic_moves: Array[Dictionary] = [
		{"from": &"E2", "to": &"E4"},
		{"from": &"E2", "to": &"D3", "capture": true},
		{"from": &"E1", "to": &"G1", "castle": &"king"},
		{"from": &"E7", "to": &"E8", "promotion": &"Queen"},
	]
	arena.show_selection(&"E2", synthetic_moves)
	await process_frame

	var names: Array[String] = []
	for child in arena.selection_root.get_children():
		names.append(String(child.name))

	for required in ["SelectedRing", "QuietMoveMarker", "CaptureMoveRing", "CastleMoveRing", "PromotionMoveRing"]:
		var found := false
		for n in names:
			if n.begins_with(required):
				found = true
				break
		if not found:
			_fail("missing tactical marker " + required + " names=" + str(names))
			return

	# Hover preview is a separate overlay layer and should communicate target intent.
	arena.show_hover(&"C3", false, false)
	await process_frame
	var hover_ring := arena.hover_root.find_child("HoverRing", true, false) as MeshInstance3D
	if hover_ring == null:
		_fail("neutral hover ring missing")
		return
	arena.show_hover(&"E4", true, false)
	await process_frame
	if arena.hover_root.find_child("HoverRing", true, false) == null:
		_fail("legal-target hover ring missing")
		return
	arena.show_hover(&"D3", true, true)
	await process_frame
	if arena.hover_root.find_child("HoverRing", true, false) == null:
		_fail("capture-target hover ring missing")
		return

	arena.show_check_danger(&"E1")
	await process_frame
	var danger_ring := arena.danger_root.find_child("CheckDangerRing", true, false) as MeshInstance3D
	if danger_ring == null:
		_fail("check danger ring missing")
		return
	var start_scale := danger_ring.scale.x
	await create_timer(0.40).timeout
	var later_scale := danger_ring.scale.x
	if absf(later_scale - start_scale) < 0.01:
		_fail("check danger ring is not pulsing")
		return

	arena.clear_selection()
	arena.clear_hover()
	arena.clear_danger()
	print("TACTICAL_FEEDBACK_PASS markers=", names.size(), " hover=ok pulse=", start_scale, "->", later_scale)
	scene.queue_free()
	await process_frame
	quit(0)
