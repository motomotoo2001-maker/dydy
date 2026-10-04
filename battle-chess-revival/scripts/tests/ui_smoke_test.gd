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
	var history_panel := controller.find_child("MoveHistoryPanel", true, false) as Control
	var history_label := controller.find_child("MoveHistoryLabel", true, false) as RichTextLabel
	var slider := controller.find_child("MasterVolume", true, false) as HSlider
	var ambience_slider := controller.find_child("AmbienceVolume", true, false) as HSlider
	var sfx_slider := controller.find_child("SFXVolume", true, false) as HSlider
	var mode_select := controller.find_child("GameMode", true, false) as OptionButton
	var ai_select := controller.find_child("AIDifficulty", true, false) as OptionButton
	var graphics_select := controller.find_child("GraphicsQuality", true, false) as OptionButton
	var capture_select := controller.find_child("CaptureMode", true, false) as OptionButton
	var resume := controller.find_child("ResumeButton", true, false) as Button
	var undo := controller.find_child("UndoButton", true, false) as Button
	var restart := controller.find_child("RestartButton", true, false) as Button

	if turn_panel == null or hint_panel == null or alert_panel == null:
		_fail("production HUD controls missing")
		return
	if pause_overlay == null or promotion_overlay == null or promotion_card == null or settings_card == null or slider == null or ambience_slider == null or sfx_slider == null or mode_select == null or ai_select == null or graphics_select == null or capture_select == null or resume == null or undo == null or restart == null:
		_fail("pause/promotion/settings/audio/mode/AI/undo controls missing")
		return
	if turn_panel.size.x > 380.0 or turn_panel.size.y > 104.0:
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

	graphics_select.select(ArenaBuilder.QUALITY_LOW)
	controller.call("_on_graphics_quality_selected", ArenaBuilder.QUALITY_LOW)
	if controller.arena.quality_preset != ArenaBuilder.QUALITY_LOW:
		_fail("graphics quality selector not wired")
		return
	var world := controller.arena.generated.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world == null or world.environment == null or world.environment.ssao_enabled or world.environment.glow_enabled:
		_fail("low graphics preset did not disable expensive effects")
		return

	graphics_select.select(ArenaBuilder.QUALITY_HIGH)
	controller.call("_on_graphics_quality_selected", ArenaBuilder.QUALITY_HIGH)
	if controller.arena.quality_preset != ArenaBuilder.QUALITY_HIGH:
		_fail("high graphics preset did not restore")
		return
	if world == null or world.environment == null or not world.environment.ssao_enabled or not world.environment.glow_enabled:
		_fail("high graphics preset did not restore approved effects")
		return

	capture_select.select(BattleDirector.CaptureMode.FAST)
	controller.call("_on_capture_mode_selected", BattleDirector.CaptureMode.FAST)
	if controller.capture_mode != BattleDirector.CaptureMode.FAST or controller.battle_director.capture_mode != BattleDirector.CaptureMode.FAST:
		_fail("Fast capture mode selector not wired")
		return
	if absf(controller.battle_director.time_scale - 0.58) > 0.001:
		_fail("Fast capture mode did not scale cinematic timing")
		return

	capture_select.select(BattleDirector.CaptureMode.OFF)
	controller.call("_on_capture_mode_selected", BattleDirector.CaptureMode.OFF)
	if controller.battle_director.capture_mode != BattleDirector.CaptureMode.OFF:
		_fail("Off capture mode selector not wired")
		return

	capture_select.select(BattleDirector.CaptureMode.FULL)
	controller.call("_on_capture_mode_selected", BattleDirector.CaptureMode.FULL)
	if controller.battle_director.capture_mode != BattleDirector.CaptureMode.FULL or absf(controller.battle_director.time_scale - 1.0) > 0.001:
		_fail("Full capture mode did not restore reference timing")
		return

	mode_select.select(1)
	controller.call("_on_game_mode_selected", 1)
	if controller.ai_enabled or not ai_select.disabled:
		_fail("local mode did not disable AI controls")
		return
	mode_select.select(0)
	controller.call("_on_game_mode_selected", 0)
	if not controller.ai_enabled or ai_select.disabled:
		_fail("AI mode did not restore AI controls")
		return

	if not history_label.text.contains("Ходов пока нет"):
		_fail("empty move history state missing")
		return

	controller.call("_toggle_pause")
	if paused or pause_overlay.visible:
		_fail("pause did not close")
		return

	var status := controller.find_child("TurnStatus", true, false) as Label
	var help := controller.find_child("HelpLabel", true, false) as Label
	var badge := controller.find_child("StateBadge", true, false) as Label
	var material_eval := controller.find_child("MaterialEval", true, false) as Label
	if status == null or status.text.is_empty():
		_fail("turn status missing")
		return
	if help == null or not help.text.contains("Esc"):
		_fail("help/onboarding text missing")
		return
	if badge == null or not badge.text.contains("Сложный"):
		_fail("AI difficulty not reflected in HUD")
		return
	if material_eval == null or not material_eval.text.contains("Материал:") or not material_eval.text.contains("0:0"):
		_fail("material/capture summary missing from HUD")
		return

	print("UI_SMOKE_PASS turn_panel=", turn_panel.size, " status=", status.text, " material=", material_eval.text, " AI=", controller.ai.difficulty_label(), " volume=", slider.value)
	scene.queue_free()
	await process_frame
	quit(0)
