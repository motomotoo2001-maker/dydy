extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("PRESENTATION_SMOKE_FAIL: " + message)
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
	if controller == null:
		_fail("ChessController missing")
		return

	var intro := controller.find_child("IntroBanner", true, false) as Control
	var endgame := controller.find_child("EndgameOverlay", true, false) as Control
	var rematch := controller.find_child("RematchButton", true, false) as Button
	var end_title := controller.find_child("EndgameTitle", true, false) as Label
	var end_subtitle := controller.find_child("EndgameSubtitle", true, false) as Label

	if intro == null or endgame == null or rematch == null or end_title == null or end_subtitle == null:
		_fail("presentation controls missing")
		return
	if intro.visible:
		_fail("intro should stay hidden in scripted render/smoke context")
		return
	if endgame.visible:
		_fail("endgame visible on startup")
		return

	controller.call("_show_endgame", &"checkmate")
	await process_frame
	if not endgame.visible or end_title.text != "ПОБЕДА" or not end_subtitle.text.contains("МАТ"):
		_fail("checkmate overlay not presented correctly")
		return

	controller.game_over = true
	controller.call("_restart_from_endgame")
	await process_frame
	if endgame.visible or controller.game_over:
		_fail("rematch flow did not reset endgame")
		return
	if controller.state.get_game_status() != &"ongoing":
		_fail("rematch did not reset chess state")
		return
	if controller.state.board.size() != 32:
		_fail("rematch board does not contain 32 pieces")
		return

	controller.call("_show_endgame", &"stalemate")
	await process_frame
	if end_title.text != "НИЧЬЯ" or end_subtitle.text != "ПАТ":
		_fail("draw overlay incorrect")
		return

	print("PRESENTATION_SMOKE_PASS title=", end_title.text, " subtitle=", end_subtitle.text)
	scene.queue_free()
	await process_frame
	quit(0)
