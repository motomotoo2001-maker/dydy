extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("PROMOTION_FLOW_FAIL: " + message)
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

	controller.ai_enabled = false
	controller.state = ChessState.new(false)
	controller.state.board = {
		&"H1": {"side": ChessState.WHITE, "type": &"King", "has_moved": true},
		&"A8": {"side": ChessState.BLACK, "type": &"King", "has_moved": true},
		&"G7": {"side": ChessState.WHITE, "type": &"Pawn", "has_moved": true},
	}
	controller.state.turn = ChessState.WHITE
	controller.state.castling_rights = {"K": false, "Q": false, "k": false, "q": false}
	controller.state.en_passant_square = &""
	controller.state.position_history.clear()
	arena.sync_pieces_from_state(controller.state)
	await process_frame

	controller._select(&"G7")
	await controller._handle_square_click(&"G8")
	if controller.promotion_overlay == null or not controller.promotion_overlay.visible:
		_fail("promotion overlay did not open")
		return
	if controller.pending_promotion_moves.size() != 4:
		_fail("promotion overlay did not receive four choices")
		return

	await controller._choose_promotion(&"Knight")
	await process_frame
	var promoted := controller.state.get_piece(&"G8")
	if promoted.is_empty() or promoted.get("type", &"") != &"Knight":
		_fail("state did not promote pawn to Knight")
		return
	var visual := arena.get_piece_at(&"G8")
	if visual == null or visual.piece_type != &"Knight":
		_fail("visual piece did not switch to Knight")
		return
	if controller.move_log.is_empty() or not controller.move_log[-1].contains("=N"):
		_fail("promotion notation did not record =N")
		return
	if controller.promotion_overlay.visible:
		_fail("promotion overlay remained visible after choice")
		return

	print("PROMOTION_FLOW_PASS move=", controller.move_log[-1])
	scene.queue_free()
	await process_frame
	quit(0)
