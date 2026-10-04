extends SceneTree

const FAMILIES := [&"Pawn", &"Knight", &"Bishop", &"Rook", &"Queen", &"King"]

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("ORDINARY_MOTION_FAIL: " + message)
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

	for family in FAMILIES:
		var piece := arena.find_piece(&"White", family)
		if piece == null or piece.visual_root == null:
			_fail("missing White " + String(family))
			return

		# Selection feedback is a root-layer lift/pulse over the authored clip.
		piece.set_selected(true)
		await process_frame
		if piece.selection_aura == null or not piece.selection_aura.visible:
			_fail("%s selection aura missing" % family)
			return
		if piece.visual_root.position.y < 0.025:
			_fail("%s selection lift too small: %s" % [family, piece.visual_root.position.y])
			return
		piece.set_selected(false)
		await process_frame

		var base_scale := Vector3.ONE * piece._design_scale(piece.piece_type)
		await piece.begin_move_presentation()
		if piece.selection_aura != null and piece.selection_aura.visible:
			_fail("%s selection aura remained visible during move" % family)
			return
		if piece.visual_root.scale.y >= base_scale.y * 0.985:
			_fail("%s anticipation did not squash enough: %s base=%s" % [family, piece.visual_root.scale, base_scale])
			return
		if absf(piece.visual_root.rotation_degrees.x) < 1.0:
			_fail("%s anticipation pitch missing" % family)
			return

		await piece.end_move_presentation()
		if piece.visual_root.scale.distance_to(base_scale) > 0.025:
			_fail("%s landing did not recover base scale: %s base=%s" % [family, piece.visual_root.scale, base_scale])
			return
		if piece.visual_root.position.length() > 0.02 or piece.visual_root.rotation_degrees.length() > 0.35:
			_fail("%s landing did not recover root transform" % family)
			return

		# Non-cinematic hit recoil must briefly move the root, then recover.
		piece.play_hit_pose()
		await create_timer(0.09).timeout
		if piece.visual_root.position.length() < 0.01 and absf(piece.visual_root.rotation_degrees.z) < 0.5:
			_fail("%s non-cinematic hit recoil missing" % family)
			return
		await create_timer(0.22).timeout
		if piece.visual_root.position.length() > 0.025:
			_fail("%s hit recoil did not recover" % family)
			return

	# Landing VFX density should communicate weight.
	var rook := arena.find_piece(&"White", &"Rook")
	if rook == null:
		_fail("White Rook missing for VFX test")
		return
	var marker := arena.get_socket(&"D4")
	arena._spawn_move_landing_fx(marker.global_position, rook)
	await process_frame
	var ring_count := 0
	var mote_count := 0
	for child in arena.generated.get_children():
		if String(child.name).begins_with("MoveLandingFX"):
			ring_count += 1
		elif String(child.name).begins_with("MoveLandingMote"):
			mote_count += 1
	if ring_count < 1 or mote_count < 7:
		_fail("Rook landing VFX density missing ring=%d motes=%d" % [ring_count, mote_count])
		return

	print("ORDINARY_MOTION_PASS families=", FAMILIES.size(), " rook_motes=", mote_count)
	scene.queue_free()
	await process_frame
	quit(0)
