extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("CAPTURE_MODE_FAIL: " + message)
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
	var battle := scene.get_node_or_null("BattleDirector") as BattleDirector
	if arena == null or battle == null:
		_fail("arena/battle missing")
		return

	battle.set_capture_mode(BattleDirector.CaptureMode.FAST)
	if battle.capture_mode != BattleDirector.CaptureMode.FAST or absf(battle.time_scale - 0.58) > 0.001:
		_fail("Fast mode contract broken")
		return
	if battle.capture_mode_label() != "Быстро":
		_fail("Fast label broken")
		return

	battle.set_capture_mode(BattleDirector.CaptureMode.FULL)
	if battle.capture_mode != BattleDirector.CaptureMode.FULL or absf(battle.time_scale - 1.0) > 0.001:
		_fail("Full mode contract broken")
		return

	var attacker := arena.find_piece(&"White", &"Pawn")
	var victim := arena.find_piece(&"Black", &"Pawn")
	if attacker == null or victim == null:
		_fail("board pawns missing")
		return
	var gameplay_camera := arena.gameplay_camera
	var battle_camera := arena.battle_camera
	if gameplay_camera == null or battle_camera == null:
		_fail("cameras missing")
		return

	battle.set_capture_mode(BattleDirector.CaptureMode.OFF)
	var impact_seen := false
	battle.capture_impact.connect(func(_id: StringName): impact_seen = true, CONNECT_ONE_SHOT)
	await battle.play_board_capture(attacker, victim)
	if not impact_seen:
		_fail("Off mode did not emit signature impact")
		return
	if battle.busy:
		_fail("Off mode remained busy")
		return
	if battle_camera.current or not gameplay_camera.current:
		_fail("Off mode switched away from gameplay camera")
		return
	if battle.capture_mode_label() != "Выкл":
		_fail("Off label broken")
		return

	print("CAPTURE_MODE_PASS off_board_space fast_scale=0.58 full_scale=1.0")
	scene.queue_free()
	await process_frame
	quit(0)
