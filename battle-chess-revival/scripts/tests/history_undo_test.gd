extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("HISTORY_UNDO_FAIL: " + message)
	paused = false
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

	var controller := scene.get_node_or_null("ChessController") as ChessController
	var arena := scene.get_node_or_null("ArenaBuilder") as ArenaBuilder
	if controller == null or arena == null:
		_fail("controller/arena missing")
		return

	# Local mode: undo one ply.
	controller.ai_enabled = false
	var e2e4 := controller.state.find_legal_move(&"E2", &"E4")
	if e2e4.is_empty():
		_fail("E2-E4 missing")
		return
	await controller._execute_move(e2e4, false)
	if controller.state.has_piece(&"E2") or not controller.state.has_piece(&"E4"):
		_fail("local move did not commit")
		return
	if controller.state_history.size() != 1 or controller.move_log.size() != 1:
		_fail("local history was not recorded")
		return
	controller.undo_last_turn()
	await process_frame
	if not controller.state.has_piece(&"E2") or controller.state.has_piece(&"E4"):
		_fail("local undo did not restore state")
		return
	if arena.get_piece_at(&"E2") == null or arena.get_piece_at(&"E4") != null:
		_fail("local undo did not restore visual board")
		return
	if not controller.state_history.is_empty() or not controller.move_log.is_empty():
		_fail("local undo did not consume history")
		return

	# AI mode semantics: one Undo returns both player and reply plies.
	controller.restart_game()
	controller.ai_enabled = true
	var white := controller.state.find_legal_move(&"E2", &"E4")
	await controller._execute_move(white, false)
	var black := controller.state.find_legal_move(&"E7", &"E5")
	if black.is_empty():
		_fail("E7-E5 missing")
		return
	await controller._execute_move(black, false)
	if controller.state_history.size() != 2 or controller.move_log.size() != 2:
		_fail("two-ply AI history not recorded")
		return
	controller.undo_last_turn()
	await process_frame
	if controller.state.turn != ChessState.WHITE:
		_fail("full-turn undo did not restore White turn")
		return
	if not controller.state.has_piece(&"E2") or not controller.state.has_piece(&"E7"):
		_fail("full-turn undo did not restore initial pawns")
		return
	if controller.state.has_piece(&"E4") or controller.state.has_piece(&"E5"):
		_fail("full-turn undo left moved pawns behind")
		return
	if arena.get_piece_at(&"E2") == null or arena.get_piece_at(&"E7") == null:
		_fail("full-turn undo visual board mismatch")
		return

	print("HISTORY_UNDO_PASS local=1ply ai=2ply")
	scene.queue_free()
	await process_frame
	quit(0)
