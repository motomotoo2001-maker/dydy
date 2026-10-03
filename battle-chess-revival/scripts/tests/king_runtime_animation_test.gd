extends SceneTree
const REQUIRED := [&"Idle",&"Selected",&"Move",&"Hit",&"Victory",&"Defeat",&"TrapdoorCommand"]
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	for side in [&"White",&"Black"]:
		var p:=PieceView.new(); get_root().add_child(p); p.setup(&"King",side,&"E1",Vector3.ZERO)
		await process_frame; await process_frame
		for clip in REQUIRED:
			if not p.has_authored_animation(clip):
				push_error("KING_RUNTIME_FAIL side=%s missing=%s" % [side,clip]); quit(2); return
		p.set_selected(true); await process_frame
		if p.current_authored_animation()!=&"Selected": push_error("KING_RUNTIME_FAIL selected"); quit(2); return
		p.set_selected(false); await process_frame
		await p.begin_move_presentation()
		if p.current_authored_animation()!=&"Move": push_error("KING_RUNTIME_FAIL move"); quit(2); return
		await p.end_move_presentation(); p.play_hit_pose(); await process_frame
		if p.current_authored_animation()!=&"Hit": push_error("KING_RUNTIME_FAIL hit"); quit(2); return
		p.reset_visual(); p.set_battle_animation_active(true)
		if not p.play_authored_animation(&"TrapdoorCommand",1.08,0.0): push_error("KING_RUNTIME_FAIL command"); quit(2); return
		await process_frame
		if p.current_authored_animation()!=&"TrapdoorCommand": push_error("KING_RUNTIME_FAIL command clip"); quit(2); return
		p.stop_authored_animation(); p.set_battle_animation_active(false); p.queue_free(); await process_frame
		print("KING_RUNTIME_OK side=",side)
	print("KING_RUNTIME_PASS"); quit(0)
