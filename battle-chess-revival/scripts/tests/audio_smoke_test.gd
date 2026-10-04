extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("AUDIO_SMOKE_FAIL: " + message)
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

	var audio := scene.get_node_or_null("AudioDirector") as AudioDirector
	if audio == null:
		_fail("AudioDirector missing")
		return
	if AudioServer.get_bus_index("Ambience") < 0 or AudioServer.get_bus_index("SFX") < 0:
		_fail("Ambience/SFX buses missing")
		return
	if audio.asset_count() != 17:
		_fail("expected 17 audio assets, got %d" % audio.asset_count())
		return

	for piece_type in [&"Pawn", &"Knight", &"Bishop", &"Rook", &"Queen", &"King"]:
		var move_key := audio.call("_move_sound_key", piece_type)
		if move_key == &"" or not audio.has_asset(move_key):
			_fail("move audio mapping missing for %s" % piece_type)
			return

	for id in [&"pawn_toe_stab", &"knight_double_kick", &"bishop_ram", &"rook_crush", &"queen_transform", &"king_trapdoor"]:
		var key := audio.capture_sound_key(id)
		if key == &"" or not audio.has_asset(key):
			_fail("capture audio mapping missing for %s" % id)
			return

	if not audio.has_asset(&"ambient") or audio.ambience_player == null:
		_fail("ambient asset/player missing")
		return
	if not audio.call("_play_key", &"select", -12.0, 1.0):
		_fail("SFX playback did not start")
		return

	print("AUDIO_SMOKE_PASS assets=", audio.asset_count(), " ambience_bus=", AudioServer.get_bus_index("Ambience"), " sfx_bus=", AudioServer.get_bus_index("SFX"))
	scene.queue_free()
	await process_frame
	quit(0)
