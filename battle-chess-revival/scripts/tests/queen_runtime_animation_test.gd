extends SceneTree

const REQUIRED := [&"Idle", &"Selected", &"Move", &"Hit", &"Victory", &"Defeat", &"TransformSpell"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for side in [&"White", &"Black"]:
		var piece := PieceView.new()
		get_root().add_child(piece)
		piece.setup(&"Queen", side, &"D1", Vector3.ZERO)
		await process_frame
		await process_frame
		for clip in REQUIRED:
			if not piece.has_authored_animation(clip):
				push_error("QUEEN_RUNTIME_FAIL side=%s missing=%s" % [side, clip])
				quit(2); return
		piece.set_selected(true); await process_frame
		if piece.current_authored_animation() != &"Selected":
			push_error("QUEEN_RUNTIME_FAIL selected side=%s clip=%s" % [side, piece.current_authored_animation()])
			quit(2); return
		piece.set_selected(false); await process_frame
		if piece.current_authored_animation() != &"Idle":
			push_error("QUEEN_RUNTIME_FAIL idle side=%s clip=%s" % [side, piece.current_authored_animation()])
			quit(2); return
		await piece.begin_move_presentation()
		if piece.current_authored_animation() != &"Move":
			push_error("QUEEN_RUNTIME_FAIL move side=%s clip=%s" % [side, piece.current_authored_animation()])
			quit(2); return
		await piece.end_move_presentation()
		piece.play_hit_pose(); await process_frame
		if piece.current_authored_animation() != &"Hit":
			push_error("QUEEN_RUNTIME_FAIL hit side=%s clip=%s" % [side, piece.current_authored_animation()])
			quit(2); return
		for clip in [&"Victory", &"Defeat"]:
			piece.reset_visual()
			if not piece.play_authored_animation(clip,1.0,0.0):
				push_error("QUEEN_RUNTIME_FAIL could_not_start side=%s clip=%s" % [side,clip])
				quit(2); return
			await process_frame
			if piece.current_authored_animation()!=clip:
				push_error("QUEEN_RUNTIME_FAIL side=%s expected=%s actual=%s" % [side,clip,piece.current_authored_animation()])
				quit(2); return
		piece.reset_visual(); piece.set_battle_animation_active(true)
		if not piece.play_authored_animation(&"TransformSpell",1.08,0.0):
			push_error("QUEEN_RUNTIME_FAIL side=%s TransformSpell did not start" % side)
			quit(2); return
		await process_frame
		if piece.current_authored_animation()!=&"TransformSpell":
			push_error("QUEEN_RUNTIME_FAIL side=%s TransformSpell=%s" % [side,piece.current_authored_animation()])
			quit(2); return
		piece.stop_authored_animation(); piece.set_battle_animation_active(false)
		piece.queue_free(); await process_frame
		print("QUEEN_RUNTIME_OK side=",side)
	print("QUEEN_RUNTIME_PASS")
	quit(0)
