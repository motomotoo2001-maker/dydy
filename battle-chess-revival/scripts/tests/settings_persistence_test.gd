extends SceneTree

const SETTINGS_PATH := "user://battle_chess_settings.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("SETTINGS_PERSISTENCE_FAIL: " + message)
	_cleanup()
	quit(2)

func _cleanup() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))

func _run() -> void:
	_cleanup()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene missing")
		return

	var first := packed.instantiate()
	root.add_child(first)
	await process_frame
	await process_frame

	var controller := first.get_node_or_null("ChessController") as ChessController
	if controller == null:
		_fail("first controller missing")
		return

	controller.ai_enabled = false
	controller.ai.set_difficulty(ChessAI.Difficulty.HARD)

	var master := AudioServer.get_bus_index("Master")
	var ambience := AudioServer.get_bus_index("Ambience")
	var sfx := AudioServer.get_bus_index("SFX")
	if master < 0 or ambience < 0 or sfx < 0:
		_fail("audio buses missing")
		return

	AudioServer.set_bus_mute(master, false)
	AudioServer.set_bus_mute(ambience, false)
	AudioServer.set_bus_mute(sfx, false)
	AudioServer.set_bus_volume_db(master, linear_to_db(0.44))
	AudioServer.set_bus_volume_db(ambience, linear_to_db(0.31))
	AudioServer.set_bus_volume_db(sfx, linear_to_db(0.67))
	controller.call("_save_settings")

	if not FileAccess.file_exists(SETTINGS_PATH):
		_fail("settings file was not created")
		return

	first.queue_free()
	await process_frame
	await process_frame

	var second := packed.instantiate()
	root.add_child(second)
	await process_frame
	await process_frame

	var restored := second.get_node_or_null("ChessController") as ChessController
	if restored == null:
		_fail("restored controller missing")
		return
	if restored.ai_enabled:
		_fail("game mode did not persist")
		return
	if restored.ai.difficulty != ChessAI.Difficulty.HARD:
		_fail("AI difficulty did not persist")
		return
	if absf(db_to_linear(AudioServer.get_bus_volume_db(master)) - 0.44) > 0.03:
		_fail("master volume did not persist")
		return
	if absf(db_to_linear(AudioServer.get_bus_volume_db(ambience)) - 0.31) > 0.03:
		_fail("ambience volume did not persist")
		return
	if absf(db_to_linear(AudioServer.get_bus_volume_db(sfx)) - 0.67) > 0.03:
		_fail("SFX volume did not persist")
		return

	print("SETTINGS_PERSISTENCE_PASS mode=local difficulty=", restored.ai.difficulty_label())
	second.queue_free()
	await process_frame
	_cleanup()
	quit(0)
