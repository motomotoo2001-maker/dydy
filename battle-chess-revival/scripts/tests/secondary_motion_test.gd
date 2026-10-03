extends SceneTree

const TYPES := [&"Pawn", &"Knight", &"Bishop", &"Rook", &"Queen", &"King"]

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("SECONDARY_MOTION_FAIL: " + message)
	quit(2)

func _run() -> void:
	for piece_type in TYPES:
		var piece := PieceView.new()
		get_root().add_child(piece)
		piece.setup(piece_type, &"White", &"D4", Vector3.ZERO)
		await process_frame
		await process_frame

		if not piece.has_authored_animation(&"Idle"):
			_fail("%s missing authored Idle" % piece_type)
			return

		var start_pos := piece.visual_root.position
		var start_rot := piece.visual_root.rotation_degrees
		var start_scale := piece.visual_root.scale
		await create_timer(0.18).timeout
		await process_frame
		var moved := piece.visual_root.position.distance_to(start_pos) > 0.0001
		moved = moved or piece.visual_root.rotation_degrees.distance_to(start_rot) > 0.01
		moved = moved or piece.visual_root.scale.distance_to(start_scale) > 0.0001
		if not moved:
			_fail("%s secondary idle root did not move" % piece_type)
			return
		if piece.current_authored_animation() != &"Idle":
			_fail("%s authored Idle not active; got=%s" % [piece_type, piece.current_authored_animation()])
			return

		piece.set_selected(true)
		await create_timer(0.12).timeout
		await process_frame
		if piece.current_authored_animation() != &"Selected":
			_fail("%s selected clip not active" % piece_type)
			return

		piece.set_selected(false)
		await process_frame
		piece.set_battle_animation_active(true)
		await process_frame
		var frozen_pos := piece.visual_root.position
		var frozen_rot := piece.visual_root.rotation_degrees
		var frozen_scale := piece.visual_root.scale
		await create_timer(0.14).timeout
		await process_frame
		if piece.visual_root.position.distance_to(frozen_pos) > 0.0001:
			_fail("%s root moved during battle lock" % piece_type)
			return
		if piece.visual_root.rotation_degrees.distance_to(frozen_rot) > 0.001:
			_fail("%s root rotated during battle lock" % piece_type)
			return
		if piece.visual_root.scale.distance_to(frozen_scale) > 0.0001:
			_fail("%s root scaled during battle lock" % piece_type)
			return

		piece.set_battle_animation_active(false)
		piece.queue_free()
		await process_frame
		print("SECONDARY_MOTION_OK type=", piece_type)

	print("SECONDARY_MOTION_PASS")
	quit(0)
