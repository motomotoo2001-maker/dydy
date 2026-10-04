extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("PLAYER_SIDE_AI_FAIL: " + message)
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

	controller.ai_enabled = true
	controller.player_side = ChessState.BLACK
	controller.ai.set_difficulty(ChessAI.Difficulty.EASY)
	controller.restart_game()

	# White AI should open automatically because the player owns Black.
	for _i in range(120):
		await process_frame
		if controller.state.turn == ChessState.BLACK and controller.move_log.size() == 1 and not controller.input_locked:
			break
	if controller.state.turn != ChessState.BLACK:
		_fail("AI did not hand turn to Black")
		return
	if controller.move_log.size() != 1 or controller.state_history.size() != 1:
		_fail("AI opener was not recorded")
		return

	var black_moves := controller.state.all_legal_moves()
	if black_moves.is_empty():
		_fail("Black player has no legal response")
		return
	var chosen: Dictionary = black_moves[0]
	var before_player := controller.state.clone()
	await controller._execute_move(chosen, false)
	if controller.state.turn != ChessState.WHITE:
		_fail("Black player move did not pass turn to White")
		return

	# Undo in Black-player mode should remove only the player's last ply and
	# return to the previous Black decision point, preserving the AI opener.
	controller.undo_last_turn()
	await process_frame
	if controller.state.turn != ChessState.BLACK:
		_fail("undo did not return to Black decision point")
		return
	if controller.move_log.size() != 1 or controller.state_history.size() != 1:
		_fail("undo removed the AI opener instead of only player move")
		return
	if controller.state.position_key() != before_player.position_key():
		_fail("undo did not restore pre-player position")
		return

	print("PLAYER_SIDE_AI_PASS opener=", controller.move_log[0], " player_side=", controller.player_side)
	scene.queue_free()
	await process_frame
	quit(0)
