extends SceneTree

const REQUIRED := [&"Idle", &"Selected", &"Move", &"Hit", &"Victory", &"Defeat", &"DoubleKick"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for side in [&"White", &"Black"]:
		var piece := PieceView.new()
		get_root().add_child(piece)
		piece.setup(&"Knight", side, &"B1", Vector3.ZERO)
		await process_frame
		await process_frame

		for clip in REQUIRED:
			if not piece.has_authored_animation(clip):
				push_error("KNIGHT_RUNTIME_FAIL side=%s missing=%s" % [side, clip])
				quit(2)
				return

		piece.set_selected(true)
		await process_frame
		if piece.current_authored_animation() != &"Selected":
			push_error("KNIGHT_RUNTIME_FAIL side=%s selected clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return

		piece.set_selected(false)
		await process_frame
		if piece.current_authored_animation() != &"Idle":
			push_error("KNIGHT_RUNTIME_FAIL side=%s idle clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return

		await piece.begin_move_presentation()
		if piece.current_authored_animation() != &"Move":
			push_error("KNIGHT_RUNTIME_FAIL side=%s move clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return
		await piece.end_move_presentation()
		if piece.current_authored_animation() != &"Idle":
			push_error("KNIGHT_RUNTIME_FAIL side=%s post-move clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return

		piece.play_hit_pose()
		await process_frame
		if piece.current_authored_animation() != &"Hit":
			push_error("KNIGHT_RUNTIME_FAIL side=%s hit clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return

		piece.reset_visual()
		piece.set_battle_animation_active(true)
		if not piece.play_authored_animation(&"DoubleKick", 1.15, 0.0):
			push_error("KNIGHT_RUNTIME_FAIL side=%s doublekick did not start" % side)
			quit(2)
			return
		await process_frame
		if piece.current_authored_animation() != &"DoubleKick":
			push_error("KNIGHT_RUNTIME_FAIL side=%s doublekick clip=%s" % [side, piece.current_authored_animation()])
			quit(2)
			return
		piece.stop_authored_animation()
		piece.set_battle_animation_active(false)

		piece.queue_free()
		await process_frame
		print("KNIGHT_RUNTIME_OK side=", side)

	print("KNIGHT_RUNTIME_PASS")
	quit(0)
