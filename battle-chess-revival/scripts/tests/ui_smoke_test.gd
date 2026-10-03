extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("UI_SMOKE_FAIL: " + message)
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
	if controller == null:
		_fail("ChessController missing")
		return

	var turn_panel := controller.find_child("TurnPanel", true, false) as Control
	var hint_panel := controller.find_child("HintPanel", true, false) as Control
	var alert_panel := controller.find_child("AlertPanel", true, false) as Control
	var pause_overlay := controller.find_child("PauseOverlay", true, false) as Control
	var promotion_overlay := controller.find_child("PromotionOverlay", true, false) as Control
	var promotion_card := controller.find_child("PromotionCard", true, false) as Control
	var settings_card := controller.find_child("SettingsCard", true, false) as Control
	var slider := controller.find_child("MasterVolume", true, false) as HSlider
	var ambience_slider := controller.find_child("AmbienceVolume", true, false) as HSlider
	var sfx_slider := controller.find_child("SFXVolume", true, false) as HSlider
	var ai_select := controller.find_child("AIDifficulty", true, false) as OptionButton
	var resume := controller.find_child("ResumeButton", true, false) as Button
	var undo := controller.find_child("UndoButton", true, false) as Button
	var restart := controller.find_child("RestartButton", true, false) as Button

	if turn_panel == null or hint_panel == null or alert_panel == null:
		_fail("production HUD controls missing")
		return
	if pause_overlay == null or promotion_overlay == null or promotion_card == null or settings_card == null or slider == null or ambience_slider == null or sfx_slider == null or ai_select == null or resume == null or undo == null or restart == null:
		_fail("pause/promotion/settings/audio/AI/undo controls missing")
		return
	if turn_panel.size.x > 380.0 or turn_panel.size.y > 90.0:
		_fail("turn panel is too large and blocks gameplay")
		return
	if pause_overlay.visible:
		_fail("pause overlay visible on startup")
		return
	if promotion_overlay.visible:
		_fail("promotion overlay visible on startup")
		return
	if alert_panel.visible:
		_fail("check/mate alert visible in ongoing game")
		return

	controller.call("_toggle_pause")
	if not paused or not pause_overlay.visible:
		_fail("pause did not open")
		return

	slider.value = 0.42
	ambience_slider.value = 0.37
	sfx_slider.value = 0.61
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		_fail("Master audio bus missing")
		return
	var linear := db_to_linear(AudioServer.get_bus_volume_db(master))
	if absf(linear - 0.42) > 0.03:
		_fail("master volume slider not wired")
		return
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if ambience_bus < 0 or sfx_bus < 0:
		_fail("audio buses missing")
		return
	if absf(db_to_linear(AudioServer.get_bus_volume_db(ambience_bus)) - 0.37) > 0.03:
		_fail("ambience volume slider not wired")
		return
	if absf(db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)) - 0.61) > 0.03:
		_fail("sfx volume slider not wired")
		return

	ai_select.select(ChessAI.Difficulty.HARD)
	controller.call("_on_ai_difficulty_selected", ChessAI.Difficulty.HARD)
	if controller.ai.difficulty != ChessAI.Difficulty.HARD:
		_fail("AI difficulty selector not wired")
		return

	controller.call("_toggle_pause")
	if paused or pause_overlay.visible:
		_fail("pause did not close")
		return

	var status := controller.find_child("TurnStatus", true, false) as Label
	var help := controller.find_child("HelpLabel", true, false) as Label
	var badge := controller.find_child("StateBadge", true, false) as Label
	if status == null or status.text.is_empty():
		_fail("turn status missing")
		return
	if help == null or not help.text.contains("Esc"):
		_fail("help/onboarding text missing")
		return
	if badge == null or not badge.text.contains("Сложный"):
		_fail("AI difficulty not reflected in HUD")
		return

	print("UI_SMOKE_PASS turn_panel=", turn_panel.size, " status=", status.text, " AI=", controller.ai.difficulty_label(), " volume=", slider.value)
	scene.queue_free()
	await process_frame
	quit(0)
