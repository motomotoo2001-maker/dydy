extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("MOVE_HINT_FAIL: " + message)
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
	var before_key := controller.state.position_key()
	await controller._request_hint()
	if controller.state.position_key() != before_key:
		_fail("hint mutated chess state")
		return
	if arena.hint_from_square == &"" or arena.hint_to_square == &"":
		_fail("hint squares missing")
		return
	if arena.hint_root == null or arena.hint_root.get_child_count() < 4:
		_fail("hint overlay is incomplete")
		return
	var legal := controller.state.find_legal_move(arena.hint_from_square, arena.hint_to_square)
	if legal.is_empty():
		_fail("hint does not describe a legal move")
		return

	await controller._execute_move(legal, false)
	if arena.hint_from_square != &"" or arena.hint_to_square != &"":
		_fail("hint did not clear after real move")
		return

	controller.undo_last_turn()
	await process_frame
	if arena.hint_root != null and arena.hint_root.get_child_count() != 0:
		_fail("undo left hint overlay behind")
		return

	print("MOVE_HINT_PASS from=", legal.get("from", &""), " to=", legal.get("to", &""))
	scene.queue_free()
	await process_frame
	quit(0)
