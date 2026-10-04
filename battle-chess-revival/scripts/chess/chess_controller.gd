class_name ChessController
extends Node

const SETTINGS_PATH := "user://battle_chess_settings.cfg"
const MATERIAL_VALUES := {
	&"Pawn": 1,
	&"Knight": 3,
	&"Bishop": 3,
	&"Rook": 5,
	&"Queen": 9,
	&"King": 0,
}

signal piece_selected(piece_type: StringName)
signal move_committed(piece_type: StringName, capture: bool)
signal game_status_changed(status: StringName)
signal game_restarted

var arena: ArenaBuilder
var battle_director: BattleDirector
var state := ChessState.new()
var ai := ChessAI.new()
var state_history: Array[ChessState] = []
var move_log: Array[String] = []
var selected_square: StringName = &""
var selected_moves: Array[Dictionary] = []
var input_locked := false
var game_over := false
var ai_enabled := true
var player_side: StringName = ChessState.WHITE
var graphics_quality := ArenaBuilder.QUALITY_HIGH
var capture_mode := BattleDirector.CaptureMode.FULL
var status_label: Label
var help_label: Label
var side_chip: Label
var state_badge: Label
var last_move_label: Label
var material_eval_label: Label
var move_history_label: RichTextLabel
var alert_panel: PanelContainer
var alert_label: Label
var pause_overlay: Control
var volume_slider: HSlider
var ambience_slider: HSlider
var sfx_slider: HSlider
var game_mode_select: OptionButton
var player_side_select: OptionButton
var ai_difficulty_select: OptionButton
var graphics_quality_select: OptionButton
var capture_mode_select: OptionButton
var hud_layer: CanvasLayer
var intro_banner: PanelContainer
var endgame_overlay: Control
var endgame_title: Label
var endgame_subtitle: Label
var promotion_overlay: Control
var pending_promotion_moves: Array[Dictionary] = []

func setup(p_arena: ArenaBuilder, p_battle_director: BattleDirector) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	arena = p_arena
	battle_director = p_battle_director
	_load_settings()
	arena.apply_quality_preset(graphics_quality)
	battle_director.set_capture_mode(capture_mode)
	_build_hud()
	_refresh_hud()
	call_deferred("_maybe_play_intro")
	call_deferred("_maybe_start_ai_turn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if promotion_overlay != null and promotion_overlay.visible:
				_cancel_promotion()
			else:
				_toggle_pause()
			get_viewport().set_input_as_handled()
			return

	if get_tree().paused:
		return
	if event is InputEventMouseMotion and arena != null and not input_locked and not battle_director.busy and not game_over:
		var hover_square := _screen_to_square(event.position)
		if hover_square == &"":
			arena.clear_hover()
		else:
			var hover_piece := state.get_piece(hover_square)
			var is_legal_target := false
			for candidate in selected_moves:
				if candidate.get("to", &"") == hover_square:
					is_legal_target = true
					break
			var enemy: bool = not hover_piece.is_empty() and hover_piece.get("side", &"") != state.turn
			arena.show_hover(hover_square, is_legal_target, enemy and is_legal_target)
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_U and arena != null and not input_locked and not battle_director.busy:
		undo_last_turn()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and game_over and not battle_director.busy:
		restart_game()
		return
	if arena == null or input_locked or battle_director.busy or game_over:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			restart_game()
			return
		if event.keycode == KEY_H:
			if not _is_ai_turn():
				call_deferred("_request_hint")
			return
		if event.keycode == KEY_A:
			ai_enabled = not ai_enabled
			_sync_game_mode_controls()
			_refresh_hud()
			_save_settings()
			if _is_ai_turn():
				call_deferred("_maybe_start_ai_turn")
			return
	if _is_ai_turn():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var square := _screen_to_square(event.position)
		if square != &"":
			_handle_square_click(square)

func _handle_square_click(square: StringName) -> void:
	var piece := state.get_piece(square)
	if selected_square == &"":
		if not piece.is_empty() and piece["side"] == state.turn:
			_select(square)
		return
	if not piece.is_empty() and piece["side"] == state.turn:
		_select(square)
		return

	var candidates: Array[Dictionary] = []
	for move in selected_moves:
		if move["to"] == square:
			candidates.append(move)
	if candidates.size() > 1 and candidates[0].has("promotion"):
		_show_promotion_choice(candidates)
		return
	if candidates.size() == 1:
		_clear_selection()
		await _execute_move(candidates[0], true)
		return
	_clear_selection()


func _select(square: StringName) -> void:
	selected_square = square
	selected_moves = state.legal_moves_from(square)
	arena.show_selection(selected_square, selected_moves)
	var selected_piece := state.get_piece(square)
	if not selected_piece.is_empty():
		piece_selected.emit(selected_piece.get("type", &""))

func _clear_selection() -> void:
	selected_square = &""
	selected_moves.clear()
	arena.clear_selection()
	arena.clear_hover()

func _execute_move(move: Dictionary, allow_ai_reply: bool) -> void:
	input_locked = true
	if arena != null:
		arena.clear_hint()
	var from_square: StringName = move["from"]
	var to_square: StringName = move["to"]
	var attacker := arena.get_piece_at(from_square)
	var captured_square := state.captured_square_for(move)
	var victim := arena.get_piece_at(captured_square) if move.get("capture", false) else null
	if attacker == null:
		push_error("No visual piece at %s" % String(from_square))
		input_locked = false
		return

	var castle_kind: StringName = move.get("castle", &"")
	var original_type := attacker.piece_type
	state_history.append(state.clone())
	if state_history.size() > 256:
		state_history.pop_front()
	if victim != null:
		await battle_director.play_board_capture(attacker, victim)
		arena.remove_piece(victim)

	state.make_move(move)
	if victim == null:
		await arena.animate_piece_move(attacker, to_square)
	else:
		arena.move_piece(attacker, to_square)
	if castle_kind != &"":
		_move_castle_rook(attacker.side, castle_kind)

	var resulting_piece := state.get_piece(to_square)
	if original_type == &"Pawn" and not resulting_piece.is_empty() and resulting_piece["type"] != &"Pawn":
		attacker.change_type(resulting_piece["type"])

	arena.show_last_move(from_square, to_square)
	move_committed.emit(original_type, victim != null)
	var status := state.get_game_status()
	move_log.append(_format_move_notation(move, original_type, victim != null, status))
	if move_log.size() > 256:
		move_log.pop_front()
	_refresh_hud()
	game_status_changed.emit(status)
	if status == &"check":
		await arena.play_check_reaction(state.turn)
	elif status == &"checkmate":
		var winner_side := ChessState.BLACK if state.turn == ChessState.WHITE else ChessState.WHITE
		await arena.play_checkmate_presentation(winner_side, state.turn)
	if status in [&"checkmate", &"stalemate", &"draw_50_move", &"draw_repetition", &"draw_insufficient"]:
		game_over = true
		_show_endgame(status)
	input_locked = false
	if allow_ai_reply and _is_ai_turn() and status in [&"ongoing", &"check"]:
		await _maybe_start_ai_turn()

func _move_castle_rook(side: StringName, kind: StringName) -> void:
	var from_square: StringName
	var to_square: StringName
	if side == ChessState.WHITE:
		from_square = &"H1" if kind == &"king" else &"A1"
		to_square = &"F1" if kind == &"king" else &"D1"
	else:
		from_square = &"H8" if kind == &"king" else &"A8"
		to_square = &"F8" if kind == &"king" else &"D8"
	var rook := arena.get_piece_at(from_square)
	if rook != null:
		arena.move_piece(rook, to_square)

func _screen_to_square(screen_position: Vector2) -> StringName:
	var camera := arena.gameplay_camera
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.0001:
		return &""
	var t := (ArenaBuilder.BOARD_Y + 0.08 - origin.y) / direction.y
	if t <= 0.0:
		return &""
	var p := origin + direction * t
	var half := ArenaBuilder.CELL_SIZE * 4.0
	if p.x < -half or p.x >= half or p.z < -half or p.z >= half:
		return &""
	var file_idx := int(floor((p.x + half) / ArenaBuilder.CELL_SIZE))
	var rank_idx := int(floor((half - p.z) / ArenaBuilder.CELL_SIZE))
	if file_idx < 0 or file_idx > 7 or rank_idx < 0 or rank_idx > 7:
		return &""
	return StringName("%s%d" % [String.chr(65 + file_idx), rank_idx + 1])

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 20
	hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud_layer)

	# Compact turn card: small footprint, high contrast, production styling.
	var turn_panel := PanelContainer.new()
	turn_panel.name = "TurnPanel"
	turn_panel.position = Vector2(20, 18)
	turn_panel.size = Vector2(350, 88)
	turn_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.045, 0.05, 0.92), Color(0.64, 0.45, 0.20, 0.90), 12, 1))
	hud_layer.add_child(turn_panel)

	var turn_margin := MarginContainer.new()
	turn_margin.add_theme_constant_override("margin_left", 14)
	turn_margin.add_theme_constant_override("margin_right", 14)
	turn_margin.add_theme_constant_override("margin_top", 6)
	turn_margin.add_theme_constant_override("margin_bottom", 6)
	turn_panel.add_child(turn_margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	turn_margin.add_child(row)

	side_chip = Label.new()
	side_chip.name = "SideChip"
	side_chip.custom_minimum_size = Vector2(44, 44)
	side_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	side_chip.add_theme_font_size_override("font_size", 24)
	side_chip.add_theme_color_override("font_color", Color("#241d1b"))
	side_chip.add_theme_stylebox_override("normal", _panel_style(Color("#e9dfce"), Color("#c3974c"), 10, 1))
	row.add_child(side_chip)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 0)
	row.add_child(text_column)

	status_label = Label.new()
	status_label.name = "TurnStatus"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#fff2dc"))
	text_column.add_child(status_label)

	state_badge = Label.new()
	state_badge.name = "StateBadge"
	state_badge.add_theme_font_size_override("font_size", 10)
	state_badge.add_theme_color_override("font_color", Color("#c8b69d"))
	text_column.add_child(state_badge)

	last_move_label = Label.new()
	last_move_label.name = "LastMove"
	last_move_label.add_theme_font_size_override("font_size", 9)
	last_move_label.add_theme_color_override("font_color", Color("#9f8f7b"))
	text_column.add_child(last_move_label)

	material_eval_label = Label.new()
	material_eval_label.name = "MaterialEval"
	material_eval_label.add_theme_font_size_override("font_size", 9)
	material_eval_label.add_theme_color_override("font_color", Color("#d7c29f"))
	text_column.add_child(material_eval_label)

	# Help is detached from the turn card so the board stays visible.
	var hint_panel := PanelContainer.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_panel.position = Vector2(-360, -58)
	hint_panel.size = Vector2(340, 38)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.03, 0.04, 0.74), Color(0.38, 0.31, 0.25, 0.72), 9, 1))
	hud_layer.add_child(hint_panel)
	help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color("#dbcdb9"))
	hint_panel.add_child(help_label)

	# Check / mate presentation.
	alert_panel = PanelContainer.new()
	alert_panel.name = "AlertPanel"
	alert_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_panel.position = Vector2(-145, 116)
	alert_panel.size = Vector2(290, 54)
	alert_panel.visible = false
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.26, 0.035, 0.035, 0.94), Color("#e5aa4e"), 12, 2))
	hud_layer.add_child(alert_panel)
	alert_label = Label.new()
	alert_label.name = "AlertLabel"
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert_label.add_theme_font_size_override("font_size", 23)
	alert_label.add_theme_color_override("font_color", Color("#fff0cf"))
	alert_panel.add_child(alert_label)

	_build_pause_overlay()
	_build_intro_banner()
	_build_endgame_overlay()
	_build_promotion_overlay()


func _build_intro_banner() -> void:
	intro_banner = PanelContainer.new()
	intro_banner.name = "IntroBanner"
	intro_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	intro_banner.position = Vector2(-170, 24)
	intro_banner.size = Vector2(340, 74)
	intro_banner.visible = false
	intro_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_banner.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.035, 0.045, 0.94), Color("#c18c42"), 12, 1))
	hud_layer.add_child(intro_banner)

	var label := Label.new()
	label.name = "IntroLabel"
	label.text = "BATTLE CHESS\nБЕЛЫЕ НАЧИНАЮТ"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#f3dfb9"))
	intro_banner.add_child(label)


func _build_endgame_overlay() -> void:
	endgame_overlay = Control.new()
	endgame_overlay.name = "EndgameOverlay"
	endgame_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	endgame_overlay.visible = false
	endgame_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	endgame_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_layer.add_child(endgame_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.018, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	endgame_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.name = "EndgameCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-220, -145)
	card.size = Vector2(440, 290)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.045, 0.055, 0.98), Color("#d0a052"), 18, 2))
	endgame_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	margin.add_child(column)

	endgame_title = Label.new()
	endgame_title.name = "EndgameTitle"
	endgame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endgame_title.add_theme_font_size_override("font_size", 34)
	endgame_title.add_theme_color_override("font_color", Color("#f4dba8"))
	column.add_child(endgame_title)

	endgame_subtitle = Label.new()
	endgame_subtitle.name = "EndgameSubtitle"
	endgame_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endgame_subtitle.add_theme_font_size_override("font_size", 16)
	endgame_subtitle.add_theme_color_override("font_color", Color("#c5b29a"))
	column.add_child(endgame_subtitle)

	var separator := HSeparator.new()
	column.add_child(separator)

	var rematch := Button.new()
	rematch.name = "RematchButton"
	rematch.text = "РЕВАНШ"
	rematch.custom_minimum_size.y = 48
	rematch.pressed.connect(_restart_from_endgame)
	column.add_child(rematch)

	var hint := Label.new()
	hint.text = "R — реванш  •  Esc — настройки"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("#8f7d70"))
	column.add_child(hint)


func _maybe_play_intro() -> void:
	# Scripted render/smoke tests instantiate main.tscn manually and therefore
	# have no current_scene equal to the game root. Keep their visual baseline clean.
	if intro_banner == null or get_tree().current_scene != get_parent():
		return
	var intro_label := intro_banner.find_child("IntroLabel", true, false) as Label
	if intro_label != null:
		intro_label.text = "BATTLE CHESS\nВЫ ИГРАЕТЕ: %s" % _side_label(player_side).to_upper()
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(intro_banner, "modulate:a", 1.0, 0.28)
	tween.tween_interval(1.05)
	tween.tween_property(intro_banner, "modulate:a", 0.0, 0.38)
	tween.tween_callback(func(): intro_banner.visible = false)


func _show_endgame(status: StringName) -> void:
	if endgame_overlay == null:
		return
	if status == &"checkmate":
		var winner := "ЧЁРНЫЕ" if state.turn == ChessState.WHITE else "БЕЛЫЕ"
		endgame_title.text = "ПОБЕДА"
		endgame_subtitle.text = "%s ПОБЕЖДАЮТ • МАТ" % winner
	else:
		endgame_title.text = "НИЧЬЯ"
		match status:
			&"stalemate": endgame_subtitle.text = "ПАТ"
			&"draw_50_move": endgame_subtitle.text = "ПРАВИЛО 50 ХОДОВ"
			&"draw_repetition": endgame_subtitle.text = "ТРОЕКРАТНОЕ ПОВТОРЕНИЕ"
			&"draw_insufficient": endgame_subtitle.text = "НЕДОСТАТОЧНО МАТЕРИАЛА"
			_: endgame_subtitle.text = "ПАРТИЯ ЗАВЕРШЕНА"
	endgame_overlay.visible = true
	endgame_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(endgame_overlay, "modulate:a", 1.0, 0.30)


func _restart_from_endgame() -> void:
	if endgame_overlay != null:
		endgame_overlay.visible = false
	restart_game()


func _build_promotion_overlay() -> void:
	promotion_overlay = Control.new()
	promotion_overlay.name = "PromotionOverlay"
	promotion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	promotion_overlay.visible = false
	promotion_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	promotion_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_layer.add_child(promotion_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.018, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	promotion_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.name = "PromotionCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-280, -82)
	card.size = Vector2(560, 164)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.043, 0.05, 0.98), Color("#d0a052"), 16, 2))
	promotion_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = "ПРЕВРАЩЕНИЕ ПЕШКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f4dba8"))
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for spec in [
		[&"Queen", "♕  ФЕРЗЬ"],
		[&"Rook", "♖  ЛАДЬЯ"],
		[&"Bishop", "♗  СЛОН"],
		[&"Knight", "♘  КОНЬ"],
	]:
		var button := Button.new()
		button.name = "Promote%s" % String(spec[0])
		button.text = spec[1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48
		button.pressed.connect(_choose_promotion.bind(spec[0]))
		row.add_child(button)


func _show_promotion_choice(moves: Array[Dictionary]) -> void:
	pending_promotion_moves.clear()
	for move in moves:
		pending_promotion_moves.append(move.duplicate(true))
	_clear_selection()
	input_locked = true
	if promotion_overlay != null:
		promotion_overlay.visible = true


func _cancel_promotion() -> void:
	pending_promotion_moves.clear()
	input_locked = false
	if promotion_overlay != null:
		promotion_overlay.visible = false


func _choose_promotion(piece_type: StringName) -> void:
	var chosen: Dictionary = {}
	for move in pending_promotion_moves:
		if move.get("promotion", &"") == piece_type:
			chosen = move
			break
	pending_promotion_moves.clear()
	if promotion_overlay != null:
		promotion_overlay.visible = false
	input_locked = false
	if not chosen.is_empty():
		await _execute_move(chosen, true)


func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_layer.add_child(pause_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.012, 0.018, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.name = "SettingsCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-205, -330)
	card.size = Vector2(410, 660)
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.055, 0.065, 0.98), Color("#b7833e"), 16, 2))
	pause_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var title := Label.new()
	title.text = "BATTLE CHESS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f4ddaf"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "ПАУЗА • НАСТРОЙКИ"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#9e8b77"))
	column.add_child(subtitle)

	var separator := HSeparator.new()
	column.add_child(separator)

	var mode_title := Label.new()
	mode_title.text = "Режим игры"
	mode_title.add_theme_font_size_override("font_size", 13)
	column.add_child(mode_title)

	game_mode_select = OptionButton.new()
	game_mode_select.name = "GameMode"
	game_mode_select.custom_minimum_size.y = 32
	game_mode_select.add_item("Против AI", 1)
	game_mode_select.add_item("Локально • 2 игрока", 0)
	game_mode_select.item_selected.connect(_on_game_mode_selected)
	column.add_child(game_mode_select)

	var side_title := Label.new()
	side_title.text = "Ваша сторона"
	side_title.add_theme_font_size_override("font_size", 13)
	column.add_child(side_title)

	player_side_select = OptionButton.new()
	player_side_select.name = "PlayerSide"
	player_side_select.custom_minimum_size.y = 32
	player_side_select.add_item("Белые", 0)
	player_side_select.add_item("Чёрные", 1)
	player_side_select.select(0 if player_side == ChessState.WHITE else 1)
	player_side_select.item_selected.connect(_on_player_side_selected)
	column.add_child(player_side_select)

	var ai_title := Label.new()
	ai_title.text = "Сложность AI"
	ai_title.add_theme_font_size_override("font_size", 13)
	column.add_child(ai_title)

	ai_difficulty_select = OptionButton.new()
	ai_difficulty_select.name = "AIDifficulty"
	ai_difficulty_select.custom_minimum_size.y = 32
	ai_difficulty_select.add_item("Лёгкий", ChessAI.Difficulty.EASY)
	ai_difficulty_select.add_item("Обычный", ChessAI.Difficulty.NORMAL)
	ai_difficulty_select.add_item("Сложный", ChessAI.Difficulty.HARD)
	ai_difficulty_select.select(ai.difficulty)
	ai_difficulty_select.item_selected.connect(_on_ai_difficulty_selected)
	column.add_child(ai_difficulty_select)
	_sync_game_mode_controls()

	var graphics_title := Label.new()
	graphics_title.text = "Качество графики"
	graphics_title.add_theme_font_size_override("font_size", 13)
	column.add_child(graphics_title)

	graphics_quality_select = OptionButton.new()
	graphics_quality_select.name = "GraphicsQuality"
	graphics_quality_select.custom_minimum_size.y = 32
	graphics_quality_select.add_item("Низкое", ArenaBuilder.QUALITY_LOW)
	graphics_quality_select.add_item("Среднее", ArenaBuilder.QUALITY_MEDIUM)
	graphics_quality_select.add_item("Высокое", ArenaBuilder.QUALITY_HIGH)
	graphics_quality_select.select(graphics_quality)
	graphics_quality_select.item_selected.connect(_on_graphics_quality_selected)
	column.add_child(graphics_quality_select)

	var capture_title := Label.new()
	capture_title.text = "Кинематографические взятия"
	capture_title.add_theme_font_size_override("font_size", 13)
	column.add_child(capture_title)

	capture_mode_select = OptionButton.new()
	capture_mode_select.name = "CaptureMode"
	capture_mode_select.custom_minimum_size.y = 30
	capture_mode_select.add_item("Выкл", BattleDirector.CaptureMode.OFF)
	capture_mode_select.add_item("Быстро", BattleDirector.CaptureMode.FAST)
	capture_mode_select.add_item("Полностью", BattleDirector.CaptureMode.FULL)
	capture_mode_select.select(capture_mode)
	capture_mode_select.item_selected.connect(_on_capture_mode_selected)
	column.add_child(capture_mode_select)

	volume_slider = _add_volume_slider(column, "Общая громкость", &"Master", "MasterVolume")
	ambience_slider = _add_volume_slider(column, "Окружение", &"Ambience", "AmbienceVolume")
	sfx_slider = _add_volume_slider(column, "Эффекты", &"SFX", "SFXVolume")

	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "ПРОДОЛЖИТЬ"
	resume.custom_minimum_size.y = 36
	resume.pressed.connect(_toggle_pause)
	column.add_child(resume)

	var undo := Button.new()
	undo.name = "UndoButton"
	undo.text = "ОТМЕНИТЬ ХОД"
	undo.custom_minimum_size.y = 34
	undo.pressed.connect(_undo_from_pause)
	column.add_child(undo)

	var restart := Button.new()
	restart.name = "RestartButton"
	restart.text = "НОВАЯ ИГРА"
	restart.custom_minimum_size.y = 36
	restart.pressed.connect(_restart_from_pause)
	column.add_child(restart)

	var tip := Label.new()
	tip.text = "Esc закрыть  •  H подсказка  •  U отмена  •  R новая игра  •  A AI"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", Color("#9e8b77"))
	column.add_child(tip)

	var history_panel := PanelContainer.new()
	history_panel.name = "MoveHistoryPanel"
	history_panel.set_anchors_preset(Control.PRESET_CENTER)
	history_panel.position = Vector2(230, -245)
	history_panel.size = Vector2(300, 490)
	history_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.038, 0.048, 0.96), Color("#80653f"), 14, 1))
	pause_overlay.add_child(history_panel)

	var history_margin := MarginContainer.new()
	history_margin.add_theme_constant_override("margin_left", 18)
	history_margin.add_theme_constant_override("margin_right", 18)
	history_margin.add_theme_constant_override("margin_top", 18)
	history_margin.add_theme_constant_override("margin_bottom", 18)
	history_panel.add_child(history_margin)

	var history_column := VBoxContainer.new()
	history_column.add_theme_constant_override("separation", 10)
	history_margin.add_child(history_column)

	var history_title := Label.new()
	history_title.text = "ИСТОРИЯ ПАРТИИ"
	history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_title.add_theme_font_size_override("font_size", 17)
	history_title.add_theme_color_override("font_color", Color("#e8c98f"))
	history_column.add_child(history_title)

	var history_scroll := ScrollContainer.new()
	history_scroll.name = "MoveHistoryScroll"
	history_scroll.custom_minimum_size = Vector2(260, 405)
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_column.add_child(history_scroll)

	move_history_label = RichTextLabel.new()
	move_history_label.name = "MoveHistoryLabel"
	move_history_label.bbcode_enabled = true
	move_history_label.fit_content = true
	move_history_label.custom_minimum_size = Vector2(250, 390)
	move_history_label.add_theme_font_size_override("normal_font_size", 14)
	move_history_label.add_theme_color_override("default_color", Color("#d6c6b0"))
	history_scroll.add_child(move_history_label)
	_refresh_move_history()


func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.36)
	style.shadow_size = 7
	return style


func _toggle_pause() -> void:
	if pause_overlay == null:
		return
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_overlay.visible = paused
	if paused:
		_refresh_move_history()


func _restart_from_pause() -> void:
	get_tree().paused = false
	if pause_overlay != null:
		pause_overlay.visible = false
	restart_game()


func _undo_from_pause() -> void:
	get_tree().paused = false
	if pause_overlay != null:
		pause_overlay.visible = false
	undo_last_turn()


func _on_game_mode_selected(index: int) -> void:
	if game_mode_select == null:
		return
	ai_enabled = game_mode_select.get_item_id(index) == 1
	_sync_game_mode_controls()
	_refresh_hud()
	_save_settings()
	if _is_ai_turn():
		call_deferred("_maybe_start_ai_turn")


func _on_player_side_selected(index: int) -> void:
	if player_side_select == null:
		return
	player_side = ChessState.WHITE if player_side_select.get_item_id(index) == 0 else ChessState.BLACK
	_save_settings()
	# Side ownership changes the AI side, so begin a clean match.
	get_tree().paused = false
	if pause_overlay != null:
		pause_overlay.visible = false
	restart_game()


func _sync_game_mode_controls() -> void:
	if game_mode_select != null:
		game_mode_select.select(0 if ai_enabled else 1)
	if ai_difficulty_select != null:
		ai_difficulty_select.disabled = not ai_enabled
	if player_side_select != null:
		player_side_select.disabled = not ai_enabled
		player_side_select.select(0 if player_side == ChessState.WHITE else 1)


func _on_ai_difficulty_selected(index: int) -> void:
	if ai_difficulty_select == null:
		return
	ai.set_difficulty(ai_difficulty_select.get_item_id(index))
	_refresh_hud()
	_save_settings()


func _on_graphics_quality_selected(index: int) -> void:
	if graphics_quality_select == null:
		return
	graphics_quality = graphics_quality_select.get_item_id(index)
	if arena != null:
		arena.apply_quality_preset(graphics_quality)
	_save_settings()


func _on_capture_mode_selected(index: int) -> void:
	if capture_mode_select == null:
		return
	capture_mode = capture_mode_select.get_item_id(index)
	if battle_director != null:
		battle_director.set_capture_mode(capture_mode)
	_refresh_hud()
	_save_settings()


func _add_volume_slider(column: VBoxContainer, title_text: String, bus_name: StringName, node_name: String) -> HSlider:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	column.add_child(title)

	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _current_bus_volume_linear(bus_name)
	slider.value_changed.connect(_on_bus_volume_changed.bind(bus_name))
	column.add_child(slider)
	return slider


func _on_bus_volume_changed(value: float, bus_name: StringName) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus, value <= 0.001)
	_save_settings()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("gameplay", "ai_enabled", ai_enabled)
	config.set_value("gameplay", "player_side", String(player_side))
	config.set_value("gameplay", "ai_difficulty", ai.difficulty)
	config.set_value("graphics", "quality", graphics_quality)
	config.set_value("gameplay", "capture_mode", capture_mode)
	config.set_value("audio", "master", _current_bus_volume_linear(&"Master"))
	config.set_value("audio", "ambience", _current_bus_volume_linear(&"Ambience"))
	config.set_value("audio", "sfx", _current_bus_volume_linear(&"SFX"))
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("Could not save settings: %s" % error_string(err))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	ai_enabled = bool(config.get_value("gameplay", "ai_enabled", true))
	player_side = StringName(config.get_value("gameplay", "player_side", String(ChessState.WHITE)))
	if player_side not in [ChessState.WHITE, ChessState.BLACK]:
		player_side = ChessState.WHITE
	ai.set_difficulty(int(config.get_value("gameplay", "ai_difficulty", ChessAI.Difficulty.NORMAL)))
	graphics_quality = clampi(int(config.get_value("graphics", "quality", ArenaBuilder.QUALITY_HIGH)), ArenaBuilder.QUALITY_LOW, ArenaBuilder.QUALITY_HIGH)
	capture_mode = clampi(int(config.get_value("gameplay", "capture_mode", BattleDirector.CaptureMode.FULL)), BattleDirector.CaptureMode.OFF, BattleDirector.CaptureMode.FULL)
	_apply_saved_bus_volume(&"Master", float(config.get_value("audio", "master", _current_bus_volume_linear(&"Master"))))
	_apply_saved_bus_volume(&"Ambience", float(config.get_value("audio", "ambience", _current_bus_volume_linear(&"Ambience"))))
	_apply_saved_bus_volume(&"SFX", float(config.get_value("audio", "sfx", _current_bus_volume_linear(&"SFX"))))


func _apply_saved_bus_volume(bus_name: StringName, value: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	var clamped := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(clamped, 0.001)))
	AudioServer.set_bus_mute(bus, clamped <= 0.001)


func _current_bus_volume_linear(bus_name: StringName) -> float:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return 1.0
	if AudioServer.is_bus_mute(bus):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.0, 1.0)


func restart_game() -> void:
	if (input_locked and not game_over) or battle_director.busy:
		return
	game_over = false
	input_locked = false
	state_history.clear()
	move_log.clear()
	pending_promotion_moves.clear()
	if promotion_overlay != null:
		promotion_overlay.visible = false
	if endgame_overlay != null:
		endgame_overlay.visible = false
	state.reset()
	arena.reset_pieces()
	arena.clear_last_move()
	arena.clear_danger()
	arena.clear_hint()
	_clear_selection()
	_refresh_hud()
	game_restarted.emit()
	if _is_ai_turn():
		call_deferred("_maybe_start_ai_turn")

func _refresh_move_history() -> void:
	if move_history_label == null:
		return
	if move_log.is_empty():
		move_history_label.text = "[center][color=#8f7d70]Ходов пока нет[/color][/center]"
		return

	var lines: Array[String] = []
	var move_number := 1
	var i := 0
	while i < move_log.size():
		var white_move := move_log[i]
		var black_move := move_log[i + 1] if i + 1 < move_log.size() else ""
		lines.append("[color=#d6b97b]%d.[/color]  %s%s" % [
			move_number,
			white_move,
			("    " + black_move) if not black_move.is_empty() else ""
		])
		move_number += 1
		i += 2
	move_history_label.text = "\n".join(lines)


func _refresh_hud() -> void:
	if status_label == null:
		return

	var status := state.get_game_status()
	if arena != null:
		arena.clear_danger()
		if status in [&"check", &"checkmate"]:
			arena.show_check_danger(state.get_king_square(state.turn))
	var white_turn := state.turn == ChessState.WHITE
	var side_text := "Белые" if white_turn else "Чёрные"
	if side_chip != null:
		side_chip.text = "♙" if white_turn else "♟"
		side_chip.add_theme_color_override("font_color", Color("#241d1b") if white_turn else Color("#f4e8d7"))
		side_chip.add_theme_stylebox_override(
			"normal",
			_panel_style(
				Color("#e9dfce") if white_turn else Color("#28232b"),
				Color("#c3974c") if white_turn else Color("#8c6372"),
				10,
				1
			)
		)

	if help_label != null:
		help_label.text = "ЛКМ ход  •  H подсказка  •  U отмена  •  Esc меню  •  A AI %s" % ("ON" if ai_enabled else "OFF")

	if state_badge != null:
		if ai_enabled:
			state_badge.text = "AI: %s  •  Вы: %s  •  %s" % [
				ai.difficulty_label(),
				_side_label(player_side),
				_material_summary()
			]
		else:
			state_badge.text = "Локальная партия  •  %s" % _material_summary()

	if last_move_label != null:
		last_move_label.text = "Последний: %s" % (move_log[-1] if not move_log.is_empty() else "—")
	if material_eval_label != null:
		material_eval_label.text = _material_advantage_summary()
	_refresh_move_history()

	if alert_panel != null:
		alert_panel.visible = status == &"check"
		if alert_label != null:
			alert_label.text = "ШАХ"

	match status:
		&"check":
			status_label.text = "%s ходят  •  ШАХ" % side_text
		&"checkmate":
			var winner := "Чёрные" if white_turn else "Белые"
			status_label.text = "Победа: %s" % winner
		&"stalemate":
			status_label.text = "ПАТ  •  ничья"
		&"draw_50_move":
			status_label.text = "НИЧЬЯ  •  50 ходов"
		&"draw_repetition":
			status_label.text = "НИЧЬЯ  •  повторение"
		&"draw_insufficient":
			status_label.text = "НИЧЬЯ  •  материал"
		_:
			if _is_ai_turn() and input_locked:
				status_label.text = "%s думают…  •  %s" % [_side_label(state.turn), ai.difficulty_label()]
			else:
				status_label.text = "%s ходят" % side_text


func undo_last_turn() -> void:
	if arena == null or battle_director == null or battle_director.busy or input_locked or state_history.is_empty():
		return
	var restored: ChessState = null
	while not state_history.is_empty():
		restored = state_history.pop_back()
		if not move_log.is_empty():
			move_log.pop_back()
		# In AI mode stop at the previous player decision point. This naturally
		# means two plies for White and one ply after the AI opener for Black.
		if not ai_enabled or restored.turn == player_side:
			break
	if restored == null:
		return
	state = restored
	game_over = false
	if endgame_overlay != null:
		endgame_overlay.visible = false
	arena.sync_pieces_from_state(state)
	arena.clear_last_move()
	arena.clear_hint()
	if not move_log.is_empty() and state_history.size() < move_log.size():
		# Defensive guard; history/log are normally kept in lockstep.
		move_log.resize(state_history.size())
	_clear_selection()
	_refresh_hud()
	game_status_changed.emit(state.get_game_status())
	if _is_ai_turn():
		call_deferred("_maybe_start_ai_turn")


func _ai_side() -> StringName:
	return ChessState.BLACK if player_side == ChessState.WHITE else ChessState.WHITE


func _is_ai_turn() -> bool:
	return ai_enabled and state.turn == _ai_side() and not game_over


func _side_label(side: StringName) -> String:
	return "Белые" if side == ChessState.WHITE else "Чёрные"


func _maybe_start_ai_turn() -> void:
	if arena == null or battle_director == null or battle_director.busy or input_locked or not _is_ai_turn():
		return
	var status := state.get_game_status()
	if status not in [&"ongoing", &"check"]:
		return
	input_locked = true
	_refresh_hud()
	await get_tree().process_frame
	await get_tree().create_timer(0.24).timeout
	var reply := ai.choose_move(state)
	input_locked = false
	_refresh_hud()
	if not reply.is_empty() and _is_ai_turn():
		await _execute_move(reply, false)


func _request_hint() -> void:
	if arena == null or battle_director == null or battle_director.busy or input_locked or game_over or _is_ai_turn():
		return
	var status := state.get_game_status()
	if status not in [&"ongoing", &"check"]:
		return
	input_locked = true
	if status_label != null:
		status_label.text = "Анализ позиции…"
	await get_tree().process_frame

	var helper_ai := ChessAI.new()
	# Hints use at least Normal depth, while respecting the user's Hard setting.
	helper_ai.set_difficulty(maxi(ai.difficulty, ChessAI.Difficulty.NORMAL))
	var hint := helper_ai.choose_move(state)
	input_locked = false
	if not hint.is_empty():
		arena.show_hint(hint.get("from", &""), hint.get("to", &""))
	_refresh_hud()


func _format_move_notation(move: Dictionary, piece_type: StringName, capture: bool, status: StringName) -> String:
	if move.has("castle"):
		return ("O-O" if move.get("castle", &"") == &"king" else "O-O-O") + ("#" if status == &"checkmate" else ("+" if status == &"check" else ""))
	var symbols := {
		&"Pawn": "",
		&"Knight": "N",
		&"Bishop": "B",
		&"Rook": "R",
		&"Queen": "Q",
		&"King": "K",
	}
	var text := "%s%s%s%s" % [
		symbols.get(piece_type, ""),
		String(move.get("from", &"")),
		("×" if capture else "–"),
		String(move.get("to", &""))
	]
	if move.has("promotion"):
		var promotion_symbols := {
			&"Queen": "Q",
			&"Rook": "R",
			&"Bishop": "B",
			&"Knight": "N",
		}
		text += "=%s" % promotion_symbols.get(move.get("promotion", &"Queen"), "Q")
	if status == &"checkmate":
		text += "#"
	elif status == &"check":
		text += "+"
	return text


func _material_summary() -> String:
	var white_count := 0
	var black_count := 0
	for square in state.board.keys():
		var piece: Dictionary = state.board[square]
		if piece.is_empty():
			continue
		if piece.get("side", &"") == ChessState.WHITE:
			white_count += 1
		elif piece.get("side", &"") == ChessState.BLACK:
			black_count += 1
	return "%d:%d" % [white_count, black_count]


func _material_advantage_summary() -> String:
	var white_value := 0
	var black_value := 0
	var white_count := 0
	var black_count := 0
	for square in state.board.keys():
		var piece: Dictionary = state.board[square]
		if piece.is_empty():
			continue
		var value: int = int(MATERIAL_VALUES.get(piece.get("type", &""), 0))
		if piece.get("side", &"") == ChessState.WHITE:
			white_value += value
			white_count += 1
		elif piece.get("side", &"") == ChessState.BLACK:
			black_value += value
			black_count += 1

	var delta := white_value - black_value
	var advantage := "="
	if delta > 0:
		advantage = "Белые +%d" % delta
	elif delta < 0:
		advantage = "Чёрные +%d" % abs(delta)

	var captured_by_white := 16 - black_count
	var captured_by_black := 16 - white_count
	return "Материал: %s  •  взято %d:%d" % [
		advantage,
		captured_by_white,
		captured_by_black
	]

