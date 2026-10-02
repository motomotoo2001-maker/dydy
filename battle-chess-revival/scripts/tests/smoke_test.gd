extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	if packed == null:
		quit(1)
		return

	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var arena := root.get_node("ArenaBuilder") as ArenaBuilder
	var director := root.get_node("BattleDirector") as BattleDirector

	_check(arena != null, "arena builder exists")
	_check(director != null, "battle director exists")
	_check(arena.get_square_count() == 64, "64 piece sockets generated")
	_check(arena.get_piece_count() == 32, "32 starting pieces generated")
	_check(director.registry_size() == 6, "six signature captures registered")

	var expected: Array[StringName] = [
		&"pawn_toe_stab",
		&"knight_double_kick",
		&"bishop_ram",
		&"rook_crush",
		&"queen_transform",
		&"king_trapdoor",
	]

	var ids := director.signature_ids()
	for id in expected:
		_check(id in ids, "registered capture: %s" % String(id))

	director.time_scale = 0.02
	for id in expected:
		print("SMOKE CAPTURE: ", id)
		await director.play_signature(id)
		_check(not director.busy, "capture finishes cleanly: %s" % String(id))

	_check(arena.get_piece_count() == 32, "capture demos preserve board roster")

	root.queue_free()
	await process_frame

	if failures == 0:
		print("BATTLE_CHESS_SMOKE_PASS")
		quit(0)
	else:
		print("BATTLE_CHESS_SMOKE_FAIL count=", failures)
		quit(1)
